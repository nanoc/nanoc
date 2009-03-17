require 'test/helper'

class Nanoc3::Filters::RDocTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    # Get filter
    filter = ::Nanoc3::Filters::RDoc.new

    # Run filter
    result = filter.run("= Foo")
    assert_equal("<h1>Foo</h1>\n", result)
  end

end
