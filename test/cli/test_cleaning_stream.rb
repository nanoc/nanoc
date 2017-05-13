# frozen_string_literal: true

require 'helper'

class Nanoc::CLI::CleaningStreamTest < Nanoc::TestCase
  class Stream
    attr_accessor :called_methods

    def initialize
      @called_methods = []
    end

    # rubocop:disable Style/MethodMissing
    def method_missing(symbol, *_args)
      @called_methods << symbol
    end
    # rubocop:enable Style/MethodMissing

    def respond_to_missing?(*_args)
      true
    end
  end

  def test_forward
    methods = %i[write << tty? tty? flush tell print puts string reopen exist? exists? close]

    s = Stream.new
    cs = Nanoc::CLI::CleaningStream.new(s)

    cs.write('aaa')
    cs << 'bb'
    cs.tty?
    cs.isatty
    cs.flush
    cs.tell
    cs.print('cc')
    cs.puts('dd')
    cs.string
    cs.reopen('/dev/null', 'r')
    cs.exist?
    cs.exists?
    cs.close

    methods.each do |m|
      assert s.called_methods.include?(m), "expected #{m} to be called"
    end
  end

  def test_forward_tty_cached
    s = Stream.new
    cs = Nanoc::CLI::CleaningStream.new(s)

    cs.tty?
    cs.isatty

    assert_equal [:tty?], s.called_methods
  end

  def test_works_with_logger
    require 'logger'
    stream = StringIO.new
    cleaning_stream = Nanoc::CLI::CleaningStream.new(stream)
    logger = Logger.new(cleaning_stream)
    logger.info('Some info')
    logger.warn('Something could start going wrong!')
  end

  def test_broken_pipe
    stream = StringIO.new
    def stream.write(_s)
      raise Errno::EPIPE.new
    end

    cleaning_stream = Nanoc::CLI::CleaningStream.new(stream)
    cleaning_stream.write('lol')
  end

  def test_non_string
    obj = Object.new
    def obj.to_s
      'Hello… world!'
    end

    stream = StringIO.new
    cleaning_stream = Nanoc::CLI::CleaningStream.new(stream)
    cleaning_stream << obj
    assert_equal 'Hello… world!', stream.string
  end

  def test_invalid_string
    s = "\x80"
    stream = StringIO.new
    cleaning_stream = Nanoc::CLI::CleaningStream.new(stream)
    cleaning_stream << s
    assert_equal "\xef\xbf\xbd", stream.string
  end
end
