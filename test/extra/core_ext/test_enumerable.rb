# encoding: utf-8

class Nanoc3::ExtraCoreExtEnumerableTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  class MyCollection

    include Enumerable

    def initialize(array)
      @array = array
    end

    def each(&block)
      @array.each { |i| block.call(i) }
    end

  end

  def test_group_by
    input = MyCollection.new([ 'foo', 'bar', 'baz' ])

    output_expected = { ?f => [ 'foo' ], ?b => [ 'bar', 'baz' ] }
    output_actual   = input.group_by { |i| i[0] }

    assert_equal output_expected, output_actual
  end

end
