require 'test/helper'

class Nanoc::BinaryFilterTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Create assets
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
    filter = Nanoc::BinaryFilter.new(asset_rep, asset, site)

    # Make sure pages and assets are not proxied by the filter
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

  def test_run
    # Create asset, page, layout
    asset_rep = mock
    asset_rep_proxy = Nanoc::Proxy.new(asset_rep)
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:to_proxy).returns(asset_proxy)
    asset.expects(:reps).returns([ asset_rep ])

    # Create page
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:to_proxy).returns(page_proxy)

    # Create layout
    layout = mock
    layout_proxy = Nanoc::Proxy.new(layout)
    layout.expects(:to_proxy).returns(layout_proxy)

    # Create site
    site = mock
    site.expects(:assets).times(2).returns([ asset ])
    site.expects(:pages).returns([ page ])
    site.expects(:layouts).returns([ layout ])
    site.expects(:config).returns({})

    # Create assets
    asset     = site.assets[0]
    asset_rep = asset.reps[0]

    # Create filter
    filter = Nanoc::BinaryFilter.new(asset_rep, asset, site)

    # Make sure an error is raised
    assert_raise(NotImplementedError) do
      filter.run(nil)
    end
  end

end
