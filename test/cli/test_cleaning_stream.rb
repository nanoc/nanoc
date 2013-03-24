# encoding: utf-8

class Nanoc::CLI::CleaningStreamTest < Nanoc::TestCase

  class Stream

    attr_accessor :called_methods

    def initialize
      @called_methods = Set.new
    end
    
    def method_missing(symbol, *args)
      @called_methods << symbol
    end

  end

  def test_forward
    methods = [ :write, :<<, :tty?, :flush, :tell, :print, :puts, :string, :reopen, :exist?, :exists?, :close ]

    s = Stream.new
    cs = Nanoc::CLI::CleaningStream.new(s)

    cs.write('aaa')
    cs << 'bb'
    cs.tty?
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

  def test_works_with_logger
    require 'logger'
    stream = StringIO.new
    cleaning_stream = Nanoc::CLI::CleaningStream.new(stream)
    logger = Logger.new(cleaning_stream)
    logger.info("Some info")
    logger.warn("Something could start going wrong!")
  end

end
