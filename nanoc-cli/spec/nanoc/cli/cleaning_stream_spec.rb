# frozen_string_literal: true

describe Nanoc::CLI::CleaningStream do
  let(:stream_class) do
    Class.new do
      attr_accessor :called_methods

      def initialize
        @called_methods = []
      end

      def method_missing(symbol, *_args) # rubocop:disable Style/MethodMissingSuper
        @called_methods << symbol
      end

      def respond_to_missing?(*_args)
        true
      end
    end
  end

  it 'forwards methods' do
    methods = %i[write << flush tell print puts string reopen exist? exists? close]

    s = stream_class.new
    cs = described_class.new(s)

    cs.write('aaa')
    cs << 'bb'
    cs.flush
    cs.tell
    cs.print('cc')
    cs.puts('dd')
    cs.string
    cs.reopen('/dev/null', 'r')
    cs.exist?
    cs.exists?
    cs.close

    expect(s.called_methods).to eq(methods)
  end

  it 'forwards #tty? and #isatty' do
    s = stream_class.new
    cs = described_class.new(s)

    cs.tty?
    cs.isatty

    expect(s.called_methods).to eq([:tty?])
  end

  it 'works with Logger' do
    require 'logger'
    stream = StringIO.new
    cleaning_stream = described_class.new(stream)
    logger = Logger.new(cleaning_stream)
    logger.info('Some info')
    logger.warn('Something could start going wrong!')
  end

  it 'handles broken pipes' do
    stream = StringIO.new
    def stream.write(_str)
      raise Errno::EPIPE.new
    end

    cleaning_stream = described_class.new(stream)
    cleaning_stream.write('lol')
  end

  it 'handles non-string objects' do
    obj = Object.new
    def obj.to_s
      'Hello… world!'
    end

    stream = StringIO.new
    cleaning_stream = described_class.new(stream)
    cleaning_stream << obj
    expect(stream.string).to eq('Hello… world!')
  end

  it 'handles invalid strings' do
    s = [128].pack('C').force_encoding('UTF-8')
    stream = StringIO.new
    cleaning_stream = described_class.new(stream)
    cleaning_stream << s
    expect(stream.string).to eq("\xef\xbf\xbd")
  end
end
