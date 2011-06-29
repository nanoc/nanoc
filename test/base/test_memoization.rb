# encoding: utf-8

class Nanoc::MemoizationTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  class Sample1

    extend Nanoc::Memoization

    def initialize(value)
      @value = value
    end

    def run(n)
      @value*10 + n
    end
    memoize :run

  end

  class Sample2

    extend Nanoc::Memoization

    def initialize(value)
      @value = value
    end

    def run(n)
      @value*100 + n
    end
    memoize :run

  end

  class EqualSample

    extend Nanoc::Memoization

    def initialize(value)
      @value = value
    end

    def hash
      4
    end

    def eql?(other)
      true
    end

    def ==(other)
      true
    end

    def run(n)
      @value*10 + n
    end
    memoize :run

  end

  def test
    sample1a = Sample1.new(10)
    sample1b = Sample1.new(15)
    sample2a = Sample2.new(20)
    sample2b = Sample2.new(25)

    3.times do
      assert_equal (10*10+5),  sample1a.run(5)
      assert_equal (10*15+7),  sample1b.run(7)
      assert_equal (100*20+5), sample2a.run(5)
      assert_equal (100*25+7), sample2b.run(7)
    end
  end

  def test_equal
    sample1 = EqualSample.new(2)
    sample2 = EqualSample.new(3)

    3.times do
      assert_equal (2*10+5), sample1.run(5)
      assert_equal (2*10+3), sample1.run(3)
      assert_equal (3*10+5), sample2.run(5)
      assert_equal (3*10+3), sample2.run(3)
    end
  end

end
