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

  def test_brackets_with_glob
    @items = Nanoc::Int::IdentifiableCollection.new({ string_pattern_type: 'glob' }, [@one, @two])

    assert_equal @one, @items['/on*/']
    assert_equal @two, @items['/*wo/']
  end

  def test_brackets_with_identifier
    assert_equal @one, @items['/one/']
    assert_equal @two, @items['/two/']
    assert_nil @items['/max-payne/']
  end

  def test_brackets_with_malformed_identifier
    assert_nil @items['one/']
    assert_nil @items['/one']
    assert_nil @items['one']
    assert_nil @items['//one/']
  end

  def test_brackets_frozen
    @items.freeze

    assert_equal @one, @items['/one/']
    assert_nil @items['/tenthousand/']
  end

  def test_regex
    foo = Nanoc::Int::Item.new('Item Foo', {}, '/foo/')
    @items = Nanoc::Int::IdentifiableCollection.new({}, [@one, @two, foo])

    assert_equal @one, @items[/n/]
    assert_equal @two, @items[%r{o/}] # not foo
  end

  def test_less_than_less_than
    assert_nil @items['/foo/']

    foo = Nanoc::Int::Item.new('Item Foo', {}, '/foo/')
    @items = Nanoc::Int::IdentifiableCollection.new({}, [@one, @two, foo])

    assert_equal foo, @items['/foo/']
  end
end
