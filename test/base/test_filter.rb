require 'helper'

class Nanoc::FilterTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize_with_page_rep
    # Create page
    page_rep = mock
    page_rep_proxy = Nanoc::Proxy.new(page_rep)
    page_rep.expects(:to_proxy).returns(page_rep_proxy)
    page_rep.expects(:attribute_named).with(:foo).returns('page rep attr foo')
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:to_proxy).times(2).returns(page_proxy)
    page.expects(:attribute_named).times(2).with(:foo).returns('page attr foo')

    # Create asset
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:to_proxy).returns(asset_proxy)
    asset.expects(:attribute_named).with(:foo).returns('asset attr foo')

    # Create layout
    layout = mock
    layout_proxy = Nanoc::Proxy.new(layout)
    layout.expects(:to_proxy).returns(layout_proxy)
    layout.expects(:attribute_named).with(:foo).returns('layout attr foo')

    # Create site
    site = mock
    site.expects(:assets).returns([ asset ])
    site.expects(:pages).returns([ page ])
    site.expects(:layouts).returns([ layout ])
    site.expects(:config).returns({})

    # Create filter
    filter = Nanoc::Filter.new(:page, page_rep, page, site)

    # Make sure page itself is not proxied by the filter
    assert_equal(
      'page attr foo',
      filter.instance_eval { @page.to_proxy.foo }
    )
    assert_equal(
      'page rep attr foo',
      filter.instance_eval { @page_rep.to_proxy.foo }
    )

    # Make sure pages, assets and layouts are proxied
    assert_equal(
      'page attr foo',
      filter.instance_eval { @pages[0].foo }
    )
    assert_equal(
      'asset attr foo',
      filter.instance_eval { @assets[0].foo }
    )
    assert_equal(
      'layout attr foo',
      filter.instance_eval { @layouts[0].foo }
    )
  end

  def test_initialize_with_asset_rep
    # Create asset
    asset_rep = mock
    asset_rep_proxy = Nanoc::Proxy.new(asset_rep)
    asset_rep.expects(:to_proxy).returns(asset_rep_proxy)
    asset_rep.expects(:attribute_named).with(:foo).returns('asset rep attr foo')
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:to_proxy).times(2).returns(asset_proxy)
    asset.expects(:attribute_named).times(2).with(:foo).returns('asset attr foo')

    # Create page
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:to_proxy).returns(page_proxy)
    page.expects(:attribute_named).with(:foo).returns('page attr foo')

    # Create layout
    layout = mock
    layout_proxy = Nanoc::Proxy.new(layout)
    layout.expects(:to_proxy).returns(layout_proxy)
    layout.expects(:attribute_named).with(:foo).returns('layout attr foo')

    # Create site
    site = mock
    site.expects(:assets).returns([ asset ])
    site.expects(:pages).returns([ page ])
    site.expects(:layouts).returns([ layout ])
    site.expects(:config).returns({})

    # Create filter
    filter = Nanoc::Filter.new(:asset, asset_rep, asset, site)

    # Make sure asset itself is not proxied by the filter
    assert_equal(
      'asset attr foo',
      filter.instance_eval { @asset.to_proxy.foo }
    )
    assert_equal(
      'asset rep attr foo',
      filter.instance_eval { @asset_rep.to_proxy.foo }
    )

    # Make sure pages, assets and layouts are proxied
    assert_equal(
      'page attr foo',
      filter.instance_eval { @pages[0].foo }
    )
    assert_equal(
      'asset attr foo',
      filter.instance_eval { @assets[0].foo }
    )
    assert_equal(
      'layout attr foo',
      filter.instance_eval { @layouts[0].foo }
    )
  end

  def test_assigns
    # Create page
    page_rep = mock
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:to_proxy).returns(page_proxy)

    # Create asset
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:to_proxy).returns(asset_proxy)

    # Create layout
    layout = mock
    layout_proxy = Nanoc::Proxy.new(layout)
    layout.expects(:to_proxy).returns(layout_proxy)

    # Create site
    site = mock
    site.expects(:assets).returns([ asset ])
    site.expects(:pages).returns([ page ])
    site.expects(:layouts).returns([ layout ])
    site.expects(:config).returns({ :xxx => 'yyy' })

    # Create filter
    filter = Nanoc::Filter.new(:page, page_rep, page, site, { :foo => 'bar' })

    # Check normal assigns
    assert_equal(page,              filter.assigns[:page])
    assert_equal(page_rep,          filter.assigns[:page_rep])
    assert_equal([ page_proxy ],    filter.assigns[:pages])
    assert_equal([ asset_proxy ],   filter.assigns[:assets])
    assert_equal([ layout_proxy ],  filter.assigns[:layouts])
    assert_equal({ :xxx => 'yyy' }, filter.assigns[:config])

    # Check other assigns
    assert_equal('bar', filter.assigns[:foo])
  end

  def test_run
    # Create page
    page_rep = mock
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:to_proxy).returns(page_proxy)

    # Create asset
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:to_proxy).returns(asset_proxy)

    # Create layout
    layout = mock
    layout_proxy = Nanoc::Proxy.new(layout)
    layout.expects(:to_proxy).returns(layout_proxy)

    # Create site
    site = mock
    site.expects(:assets).returns([ asset ])
    site.expects(:pages).returns([ page ])
    site.expects(:layouts).returns([ layout ])
    site.expects(:config).returns({ :xxx => 'yyy' })

    # Create filter
    filter = Nanoc::Filter.new(:page, page_rep, page, site, { :foo => 'bar' })

    # Make sure an error is raised
    assert_raise(NotImplementedError) do
      filter.run(nil)
    end
  end

  def test_extensions
    # Create page
    page_rep = mock
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:to_proxy).returns(page_proxy)

    # Create asset
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:to_proxy).returns(asset_proxy)

    # Create layout
    layout = mock
    layout_proxy = Nanoc::Proxy.new(layout)
    layout.expects(:to_proxy).returns(layout_proxy)

    # Create site
    site = mock
    site.expects(:assets).returns([ asset ])
    site.expects(:pages).returns([ page ])
    site.expects(:layouts).returns([ layout ])
    site.expects(:config).returns({ :xxx => 'yyy' })

    # Create filter
    filter = Nanoc::Filter.new(:page, page_rep, page, site, { :foo => 'bar' })

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
