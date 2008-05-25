require 'helper'

class Nanoc::FilterTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestPage

    def to_proxy
      @proxy ||= Nanoc::Proxy.new(self)
    end

    def attribute_named(key)
      "page attribute named #{key}"
    end

  end

  class TestLayout

    def to_proxy
      @proxy ||= Nanoc::Proxy.new(self)
    end

    def attribute_named(key)
      "layout attribute named #{key}"
    end

  end

  class TestSite

    def config
      "Not a real config."
    end

    def pages
      @pages ||= [ TestPage.new ]
    end

    def layouts
      @layouts ||= [ TestLayout.new ]
    end

  end

  def test_initialize
    # Create site and filter
    site = TestSite.new
    filter = Nanoc::Filter.new(site.pages[0], site)

    # Make sure page itself is not proxied by the filter
    assert_equal(
      'page attribute named foo',
      filter.instance_eval { @page.to_proxy.foo }
    )

    # Make sure pages and layouts are proxied
    assert_equal(
      'page attribute named foo',
      filter.instance_eval { @pages[0].foo }
    )
    assert_equal(
      'layout attribute named foo',
      filter.instance_eval { @layouts[0].foo }
    )
  end

  def test_assigns
    # Create site and filter
    site = TestSite.new
    filter = Nanoc::Filter.new(site.pages[0], site, { :foo => 'bar' })

    # Check normal assigns
    assert_equal(site.config,                         filter.assigns[:config])
    assert_equal(site.pages[0],                       filter.assigns[:page])
    assert_equal(site.pages.map   { |p| p.to_proxy }, filter.assigns[:pages])
    assert_equal(site.layouts.map { |l| l.to_proxy }, filter.assigns[:layouts])

    # Check other assigns
    assert_equal('bar',                               filter.assigns[:foo])
  end

  def test_run
    # Create site and filter
    site = TestSite.new
    filter = Nanoc::Filter.new(site.pages[0], site)

    # Make sure an error is raised
    assert_raise(NotImplementedError) do
      filter.run(nil)
    end
  end

  def test_extensions
    # Create site and filter
    site = TestSite.new
    filter = Nanoc::Filter.new(site.pages[0], site)

    # Update extension
    filter.class.class_eval { extension :foo }

    # Check
    assert_equal(:foo, filter.class.class_eval { extension })
    assert_equal([ :foo ], filter.class.class_eval { extensions })

    # Update extension
    filter.class.class_eval { extensions :foo, :bar }

    # Check
    assert_equal([ :foo, :bar ], filter.class.class_eval { extensions })
  end

end
