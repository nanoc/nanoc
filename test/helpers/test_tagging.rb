require 'test/helper'

class Nanoc3::Helpers::TaggingTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::Tagging

  def test_tags_for_without_tags
    # Create page
    page = Nanoc3::Page.new('content', {}, '/path/')
    page_proxy = page.to_proxy

    # Check
    assert_equal(
      '(none)',
      tags_for(page_proxy)
    )
  end

  def test_tags_for_with_custom_base_url
    # Create page
    page = Nanoc3::Page.new('content', { :tags => [ 'foo', 'bar' ]}, '/path/')
    page_proxy = page.to_proxy

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://stoneship.org/tag/')}, " +
      "#{link_for_tag('bar', 'http://stoneship.org/tag/')}",
      tags_for(page_proxy, :base_url => 'http://stoneship.org/tag/')
    )
  end

  def test_tags_for_with_custom_none_text
    # Create page
    page = Nanoc3::Page.new('content', { :tags => [ ]}, '/path/')
    page_proxy = page.to_proxy

    # Check
    assert_equal(
      'no tags for you, fool',
      tags_for(page_proxy, :none_text => 'no tags for you, fool')
    )
  end

  def test_tags_for_with_custom_separator
    # Create page
    page = Nanoc3::Page.new('content', { :tags => [ 'foo', 'bar' ]}, '/path/')
    page_proxy = page.to_proxy

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://technorati.com/tag/')} ++ " +
      "#{link_for_tag('bar', 'http://technorati.com/tag/')}",
      tags_for(page_proxy, :separator => ' ++ ')
    )
  end

  def test_pages_with_tag
    # Create pages
    pages = [
      Nanoc3::Page.new('page 1', { :tags => [ :foo ]}, '/page1/'),
      Nanoc3::Page.new('page 2', { :tags => [ :bar ]}, '/page2/'),
      Nanoc3::Page.new('page 3', { :tags => [ :foo, :bar ]}, '/page3/')
    ]
    @pages = pages.map { |p| p.to_proxy }

    # Find pages
    pages_with_foo_tag = pages_with_tag(:foo)

    # Check
    assert_equal(
      [ pages[0], pages[2] ].map { |p| p.to_proxy },
      pages_with_foo_tag
    )
  end

  def test_link_for_tag
    assert_equal(
      %[<a href="http://stoneship.org/tags/foobar" rel="tag">foobar</a>],
      link_for_tag('foobar', 'http://stoneship.org/tags/')
    )
  end

end
