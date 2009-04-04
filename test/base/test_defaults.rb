require 'test/helper'

class Nanoc::DefaultsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Make sure attributes are cleaned
    page_defaults = Nanoc::PageDefaults.new({ 'foo' => 'bar' })
    assert_equal({ :foo => 'bar' }, page_defaults.attributes)
  end

end
