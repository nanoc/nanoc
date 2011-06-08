# encoding: utf-8

class Nanoc3::MemoizationTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  class Sample1

    extend Nanoc3::Memoization

    def initialize(value)
      @value = value
    end

    def run(n)
      @value*10 + n
    end
    memoize :run

  end

  class Sample2

    extend Nanoc3::Memoization

    def initialize(value)
      @value = value
    end

    def run(n)
      @value*100 + n
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

end
