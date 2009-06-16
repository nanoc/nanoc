# encoding: utf-8

require 'test/helper'

class Nanoc3::ItemTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_initialize_with_attributes_with_string_keys
    item = Nanoc3::Item.new("foo", { 'abc' => 'xyz' }, '/foo/')

    assert_equal nil,   item.attributes['abc']
    assert_equal 'xyz', item.attributes[:abc]
  end

  def test_initialize_with_unclean_identifier
    item = Nanoc3::Item.new("foo", {}, '/foo')

    assert_equal '/foo/', item.identifier
  end

  def test_lookup
    # Create item
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

  def test_set_attribute
    item = Nanoc3::Item.new("foo", {}, '/foo')
    assert_equal nil, item[:motto]

    item[:motto] = 'More human than human'
    assert_equal 'More human than human', item[:motto]
  end

end
