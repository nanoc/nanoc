require 'test/helper'

class Nanoc::Filters::RDocTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_nothing_raised do
      # Get filter
      filter = ::Nanoc::Filters::RDoc.new

      # Run filter
      result = filter.run("= Foo")
      assert_equal("<h1>Foo</h1>\n", result)
    end
  end

end
