require 'test/helper'

class Nanoc3::ItemTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_to_proxy
    # Mock item
    item = Nanoc3::Item.new('sample content', { :sample => 'attributes' }, '/sample/path/')

    # Create proxy
    item_proxy = item.to_proxy

    # Test
    assert_equal(item, item_proxy.instance_eval { @obj })
  end

  def test_lookup
    # Create item and rep
    item = Nanoc3::Item.new(
      "content",
      { :one => 'one in item' },
      '/path/'
    )

    # Test finding one
    assert_equal('one in item', item[:one])

    # Test finding two
    assert_equal(nil, item[:two])
  end

end
