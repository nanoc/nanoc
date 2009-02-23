require 'test/helper'

class Nanoc::ItemTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_stub
  end

  def test_to_proxy
    # TODO implement
  end

  def test_attribute_named
    # Create item and rep
    item = Nanoc::Item.new(
      "content",
      { :one => 'one in item' },
      '/path/'
    )

    # Test finding one
    assert_equal('one in item', item.attribute_named(:one))

    # Test finding two
    assert_equal(nil, item.attribute_named(:two))
  end

end
