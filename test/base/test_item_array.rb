# frozen_string_literal: true

require 'helper'

class Nanoc::Int::IdentifiableCollectionTest < Nanoc::TestCase
  def setup
    super

    @one = Nanoc::Int::Item.new('Item One', {}, '/one/')
    @two = Nanoc::Int::Item.new('Item Two', {}, '/two/')

    @items = Nanoc::Int::IdentifiableCollection.new({}, [@one, @two])
  end

  def test_change_item_identifier
    assert_equal @one, @items['/one/']
    assert_nil @items['/foo/']

    @one.identifier = '/foo/'

    assert_nil @items['/one/']
    assert_equal @one, @items['/foo/']
  end

  def test_enumerable
    assert_equal @one, @items.find { |i| i.identifier == '/one/' }
  end

  def test_less_than_less_than
    assert_nil @items['/foo/']

    foo = Nanoc::Int::Item.new('Item Foo', {}, '/foo/')
    @items = Nanoc::Int::IdentifiableCollection.new({}, [@one, @two, foo])

    assert_equal foo, @items['/foo/']
  end
end
