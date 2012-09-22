# encoding: utf-8

class Nanoc::CLI::CleaningStreamTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

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
    methods = [ :write, :<<, :tty?, :flush, :tell, :print, :puts, :string, :reopen, :exist?, :exists? ]

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

    methods.each do |m|
      assert s.called_methods.include?(m), "expected #{m} to be called"
    end
  end

end

