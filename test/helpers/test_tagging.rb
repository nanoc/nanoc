# encoding: utf-8

class Nanoc::Helpers::TaggingTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::Tagging

  def test_tags_for_without_tags
    # Create item
    item = Nanoc::Item.new('content', {}, '/path/')

    # Check
    assert_equal(
      '(none)',
      tags_for(item)
    )
  end

  def test_tags_for_with_custom_base_url
    # Create item
    item = Nanoc::Item.new('content', { :tags => [ 'foo', 'bar' ]}, '/path/')

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://stoneship.org/tag/')}, " +
      "#{link_for_tag('bar', 'http://stoneship.org/tag/')}",
      tags_for(item, :base_url => 'http://stoneship.org/tag/')
    )
  end

  def test_tags_for_with_custom_none_text
    # Create item
    item = Nanoc::Item.new('content', { :tags => [ ]}, '/path/')

    # Check
    assert_equal(
      'no tags for you, fool',
      tags_for(item, :none_text => 'no tags for you, fool')
    )
  end

  def test_tags_for_with_custom_separator
    # Create item
    item = Nanoc::Item.new('content', { :tags => [ 'foo', 'bar' ]}, '/path/')

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://technorati.com/tag/')} ++ " +
      "#{link_for_tag('bar', 'http://technorati.com/tag/')}",
      tags_for(item, :separator => ' ++ ')
    )
  end

  def test_items_with_tag
    # Create items
    @items = [
      Nanoc::Item.new('item 1', { :tags => [ :foo ]       }, '/item1/'),
      Nanoc::Item.new('item 2', { :tags => [ :bar ]       }, '/item2/'),
      Nanoc::Item.new('item 3', { :tags => [ :foo, :bar ] }, '/item3/')
    ]

    # Find items
    items_with_foo_tag = items_with_tag(:foo)

    # Check
    assert_equal(
      [ @items[0], @items[2] ],
      items_with_foo_tag
    )
  end

  def test_link_for_tag
    assert_equal(
      %[<a href="http://stoneship.org/tags/foobar" rel="tag">foobar</a>],
      link_for_tag('foobar', 'http://stoneship.org/tags/')
    )
  end

  def test_link_for_tag_escape
    assert_equal(
      %[<a href="http://stoneship.org/tags&amp;stuff/foo&amp;bar" rel="tag">foo&amp;bar</a>],
      link_for_tag('foo&bar', 'http://stoneship.org/tags&stuff/')
    )
  end

end
