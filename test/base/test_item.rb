# frozen_string_literal: true

require 'helper'

class Nanoc::Int::ItemTest < Nanoc::TestCase
  def test_initialize_with_attributes_with_string_keys
    item = Nanoc::Int::Item.new('foo', { 'abc' => 'xyz' }, '/foo/')

    assert_equal nil,   item.attributes['abc']
    assert_equal 'xyz', item.attributes[:abc]
  end

  def test_reference
    item = Nanoc::Int::Item.new(
      'content',
      { one: 'one in item' },
      '/path/',
    )

    assert_equal([:item, '/path/'], item.reference)
  end

  def test_attributes
    item = Nanoc::Int::Item.new('content', { 'one' => 'one in item' }, '/path/')
    assert_equal({ one: 'one in item' }, item.attributes)
  end

  def test_freeze_should_disallow_changes
    item = Nanoc::Int::Item.new('foo', { a: { b: 123 } }, '/foo/')
    item.freeze

    assert_raises_frozen_error do
      item.attributes[:abc] = '123'
    end

    assert_raises_frozen_error do
      item.attributes[:a][:b] = '456'
    end
  end
end
