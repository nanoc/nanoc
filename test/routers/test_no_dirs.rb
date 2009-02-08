require 'test/helper'

class Nanoc::Routers::NoDirsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_path_for_root_page_rep
    # Create no-dirs router
    router = Nanoc::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get page
    page = Nanoc::Page.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/'
    )
    page_rep = Nanoc::PageRep.new(page, :default)

    # Check
    assert_equal('/home.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_page_rep_with_default_rep
    # Create no-dirs router
    router = Nanoc::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get page
    page = Nanoc::Page.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/foo/'
    )
    page_rep = Nanoc::PageRep.new(page, :default)

    # Check
    assert_equal('/foo.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_page_rep_with_custom_rep
    # Create no-dirs router
    router = Nanoc::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get page
    page = Nanoc::Page.new(
      'some content',
      {
        :filename => 'home',
        :extension => 'htm'
      },
      '/foo/'
    )
    page_rep = Nanoc::PageRep.new(page, :raw)

    # Check
    assert_equal('/foo-raw.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_asset_rep_with_default_rep
    # Create site
    site = mock
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create default router
    router = Nanoc::Routers::Default.new(site)

    # Get asset
    asset = Nanoc::Asset.new(
      nil,
      { :extension => 'png' },
      '/foo/'
    )
    asset_rep = Nanoc::AssetRep.new(asset, :default)

    # Check
    assert_equal('/imuhgez/foo.png', router.path_for_asset_rep(asset_rep))
  end

  def test_path_for_asset_rep_with_custom_rep
    # Create site
    site = mock
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create default router
    router = Nanoc::Routers::Default.new(site)

    # Get asset
    asset = Nanoc::Asset.new(
      nil,
      { :extension => 'png' },
      '/foo/'
    )
    asset_rep = Nanoc::AssetRep.new(asset, :raw)

    # Check
    assert_equal('/imuhgez/foo-raw.png', router.path_for_asset_rep(asset_rep))
  end

end
