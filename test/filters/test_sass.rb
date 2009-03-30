require 'helper'

class Nanoc::Filters::SassTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter_with_page_rep
    if_have 'haml' do
      assert_nothing_raised do
        # Create site
        site = mock

        # Create page
        page = mock
        page_proxy = Nanoc::Proxy.new(page)
        page.expects(:site).returns(site)

        # Create page rep
        page_rep = mock
        page_rep_proxy = Nanoc::Proxy.new(page_rep)
        page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
        page_rep.expects(:page).returns(page)
        page_rep.expects(:attribute_named).with(:sass_options).returns({})

        # Get filter
        filter = ::Nanoc::Filters::Sass.new(page_rep)

        # Run filter
        result = filter.run(".foo #bar\n  color: #f00")
        assert_match(/.foo\s+#bar\s*\{\s*color:\s+#f00;?\s*\}/, result)
      end
    end
  end

  def test_filter_with_asset_rep
    if_have 'haml' do
      assert_nothing_raised do
        # Create site
        site = mock

        # Create asset
        asset = mock
        asset_proxy = Nanoc::Proxy.new(asset)
        asset.expects(:site).returns(site)

        # Create asset rep
        asset_rep = mock
        asset_rep_proxy = Nanoc::Proxy.new(asset_rep)
        asset_rep.expects(:is_a?).with(Nanoc::PageRep).returns(false)
        asset_rep.expects(:asset).returns(asset)
        asset_rep.expects(:attribute_named).with(:sass_options).returns({})

        # Get filter
        filter = ::Nanoc::Filters::Sass.new(asset_rep)

        # Run filter
        result = filter.run(".foo #bar\n  color: #f00")
        assert_match(/.foo\s+#bar\s*\{\s*color:\s+#f00;?\s*\}/, result)
      end
    end
  end

end
