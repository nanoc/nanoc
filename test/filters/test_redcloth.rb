require 'test/helper'

class Nanoc::Filters::RedClothTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'redcloth' do
      assert_nothing_raised do
        # Get filter
        filter = ::Nanoc::Filters::RedCloth.new

        # Run filter
        result = filter.run("h1. Foo")
        assert_equal("<h1>Foo</h1>", result)
      end
    end
  end

end
