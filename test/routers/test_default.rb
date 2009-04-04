require 'test/helper'

class Nanoc::Routers::DefaultTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_path_for_page_rep_with_default_rep
    # Create default router
    router = Nanoc::Routers::Default.new(nil)

    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Get page
    page = Nanoc::Page.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/foo/'
    )
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Check
    assert_equal('/foo/home.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_page_rep_with_custom_rep
    # Create default router
    router = Nanoc::Routers::Default.new(nil)

    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Get page
    page = Nanoc::Page.new(
      'some content',
      { :reps => { :raw => {
        :filename => 'home',
        :extension => 'htm'
      }}},
      '/foo/'
    )
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :raw }

    # Check
    assert_equal('/foo/home-raw.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_asset_rep_with_default_rep
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).at_least_once.returns(asset_defaults)
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create default router
    router = Nanoc::Routers::Default.new(site)

    # Get asset
    asset = Nanoc::Asset.new(
      nil,
      { :extension => 'png' },
      '/foo/'
    )
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps[0]

    # Check
    assert_equal('/imuhgez/foo.png', router.path_for_asset_rep(asset_rep))
  end

  def test_path_for_asset_rep_with_custom_rep
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).at_least_once.returns(asset_defaults)
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create default router
    router = Nanoc::Routers::Default.new(site)

    # Get asset
    asset = Nanoc::Asset.new(
      nil,
      { :reps => { :raw => {
        :extension => 'png'
      }}},
      '/foo/'
    )
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps.find { |r| r.name == :raw }

    # Check
    assert_equal('/imuhgez/foo-raw.png', router.path_for_asset_rep(asset_rep))
  end

end
