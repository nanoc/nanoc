require 'test/helper'

class Nanoc3::ItemTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_to_proxy
    # TODO implement
  end

  def test_attribute_named
    # Create item and rep
    item = Nanoc3::Item.new(
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
