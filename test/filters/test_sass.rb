require 'test/helper'

class Nanoc::Filters::SassTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter_with_page_rep
    if_have 'haml' do
      # Create site
      site = mock

      # Create page
      page = mock
      page_proxy = Nanoc::Proxy.new(page)
      page.stubs(:site).returns(site)
      page.stubs(:to_proxy).returns(page_proxy)
      page.stubs(:path).returns('/moo/')

      # Create page rep
      page_rep = mock
      page_rep_proxy = Nanoc::Proxy.new(page_rep)
      page_rep.stubs(:is_a?).with(Nanoc::PageRep).returns(true)
      page_rep.stubs(:page).returns(page)
      page_rep.stubs(:to_proxy).returns(page_rep_proxy)
      page_rep.stubs(:attribute_named).with(:sass_options).returns({})
      page_rep.stubs(:name).returns(:foobar)

      # Mock site
      site.stubs(:pages).returns([])
      site.stubs(:assets).returns([])
      site.stubs(:layouts).returns([])
      site.stubs(:config).returns({})

      # Get filter
      filter = ::Nanoc::Filters::Sass.new(page_rep)

      # Run filter
      result = filter.run(".foo #bar\n  color: #f00")
      assert_match(/.foo\s+#bar\s*\{\s*color:\s+#f00;?\s*\}/, result)
    end
  end

  def test_filter_with_asset_rep
    if_have 'haml' do
      # Create site
      site = mock

      # Create asset
      asset = mock
      asset_proxy = Nanoc::Proxy.new(asset)
      asset.stubs(:to_proxy).returns(asset_proxy)
      asset.expects(:site).returns(site)
      asset.stubs(:path).returns('/moo/')

      # Create asset rep
      asset_rep = mock
      asset_rep_proxy = Nanoc::Proxy.new(asset_rep)
      asset_rep.expects(:is_a?).with(Nanoc::PageRep).returns(false)
      asset_rep.expects(:asset).returns(asset)
      asset_rep.stubs(:to_proxy).returns(asset_rep_proxy)
      asset_rep.expects(:attribute_named).with(:sass_options).returns({})
      asset_rep.stubs(:name).returns(:foobar)

      # Mock site
      site.stubs(:pages).returns([])
      site.stubs(:assets).returns([])
      site.stubs(:layouts).returns([])
      site.stubs(:config).returns({})

      # Get filter
      filter = ::Nanoc::Filters::Sass.new(asset_rep)

      # Run filter
      result = filter.run(".foo #bar\n  color: #f00")
      assert_match(/.foo\s+#bar\s*\{\s*color:\s+#f00;?\s*\}/, result)
    end
  end

end
