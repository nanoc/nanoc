require 'helper'

class PageTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Make sure attributes are cleaned
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, page.attributes)

    # Make sure path is fixed
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, 'foo')
    assert_equal('/foo/', page.path)
  end

  def test_to_proxy
    # Create page
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, page.attributes)

    # Create proxy
    page_proxy = page.to_proxy

    # Check values
    assert_equal('bar', page_proxy.foo)
  end

  def test_modified
    # TODO implement
  end

  def test_created
    # TODO implement
  end

  def test_outdated
    # TODO implement
  end

  def test_attribute_named
    # Create site
    site = Nanoc::Site.new({})

    # Create page defaults (hacky...)
    page_defaults = Nanoc::PageDefaults.new({ :quux => 'stfu' })
    site.instance_eval { @page_defaults = page_defaults }

    # Create page
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    page.site = site

    # Test
    assert_equal('bar',  page.attribute_named(:foo))
    assert_equal('html', page.attribute_named(:extension))
    assert_equal('stfu', page.attribute_named(:quux))

    # Create page
    page = Nanoc::Page.new("content", { 'extension' => 'php' }, '/foo/')
    page.site = site

    # Test
    assert_equal(nil,    page.attribute_named(:foo))
    assert_equal('php',  page.attribute_named(:extension))
    assert_equal('stfu', page.attribute_named(:quux))
  end

  def test_content
    # TODO implement
  end

  def test_layout
    # TODO implement
  end

  def test_disk_path
    # TODO implement
  end

  def test_web_path
    # TODO implement
  end

  def test_compile
    # TODO implement
  end

  def test_filter!
    # TODO implement
  end

  def test_layout!
    # TODO implement
  end

end
