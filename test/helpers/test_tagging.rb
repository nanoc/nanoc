require 'test/helper'

class Nanoc3::Helpers::TaggingTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::Tagging

  def test_tags_for_without_tags
    # Create item
    item = Nanoc3::Item.new('content', {}, '/path/')
    item_proxy = item.to_proxy

    # Check
    assert_equal(
      '(none)',
      tags_for(item_proxy)
    )
  end

  def test_tags_for_with_custom_base_url
    # Create item
    item = Nanoc3::Item.new('content', { :tags => [ 'foo', 'bar' ]}, '/path/')
    item_proxy = item.to_proxy

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://stoneship.org/tag/')}, " +
      "#{link_for_tag('bar', 'http://stoneship.org/tag/')}",
      tags_for(item_proxy, :base_url => 'http://stoneship.org/tag/')
    )
  end

  def test_tags_for_with_custom_none_text
    # Create item
    item = Nanoc3::Item.new('content', { :tags => [ ]}, '/path/')
    item_proxy = item.to_proxy

    # Check
    assert_equal(
      'no tags for you, fool',
      tags_for(item_proxy, :none_text => 'no tags for you, fool')
    )
  end

  def test_tags_for_with_custom_separator
    # Create item
    item = Nanoc3::Item.new('content', { :tags => [ 'foo', 'bar' ]}, '/path/')
    item_proxy = item.to_proxy

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://technorati.com/tag/')} ++ " +
      "#{link_for_tag('bar', 'http://technorati.com/tag/')}",
      tags_for(item_proxy, :separator => ' ++ ')
    )
  end

  def test_items_with_tag
    # Create items
    items = [
      Nanoc3::Item.new('item 1', { :tags => [ :foo ]       }, '/item1/'),
      Nanoc3::Item.new('item 2', { :tags => [ :bar ]       }, '/item2/'),
      Nanoc3::Item.new('item 3', { :tags => [ :foo, :bar ] }, '/item3/')
    ]
    @items = items.map { |i| i.to_proxy }

    # Find items
    items_with_foo_tag = items_with_tag(:foo)

    # Check
    assert_equal(
      [ items[0], items[2] ].map { |i| i.to_proxy },
      items_with_foo_tag
    )
  end

  def test_link_for_tag
    assert_equal(
      %[<a href="http://stoneship.org/tags/foobar" rel="tag">foobar</a>],
      link_for_tag('foobar', 'http://stoneship.org/tags/')
    )
  end

end
