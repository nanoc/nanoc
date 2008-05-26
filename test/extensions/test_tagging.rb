require 'helper'

class Nanoc::Extensions::TaggingTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Extensions::Tagging

  class TestSite

    def page_defaults
      @page_defaults ||= Nanoc::PageDefaults.new({})
    end

  end

  def test_tags_for_without_tags
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new('content', {}, '/path/')
    page.site = site
    page_proxy = page.to_proxy

    # Check
    assert_equal(
      '(none)',
      tags_for(page_proxy)
    )
  end

  def test_tags_for_with_custom_base_url
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new('content', { :tags => [ 'foo', 'bar' ]}, '/path/')
    page.site = site
    page_proxy = page.to_proxy

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://stoneship.org/tag/')}, " +
      "#{link_for_tag('bar', 'http://stoneship.org/tag/')}",
      tags_for(page_proxy, :base_url => 'http://stoneship.org/tag/')
    )
  end

  def test_tags_for_with_custom_none_text
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new('content', { :tags => [ ]}, '/path/')
    page.site = site
    page_proxy = page.to_proxy

    # Check
    assert_equal(
      'no tags for you, fool',
      tags_for(page_proxy, :none_text => 'no tags for you, fool')
    )
  end

  def test_tags_for_with_custom_separator
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new('content', { :tags => [ 'foo', 'bar' ]}, '/path/')
    page.site = site
    page_proxy = page.to_proxy

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://technorati.com/tag/')} ++ " +
      "#{link_for_tag('bar', 'http://technorati.com/tag/')}",
      tags_for(page_proxy, :separator => ' ++ ')
    )
  end

  def test_link_for_tag
    assert_equal(
      %[<a href="http://stoneship.org/tags/foobar" rel="tag">foobar</a>],
      link_for_tag('foobar', 'http://stoneship.org/tags/')
    )
  end

end
