require 'test/helper'

class Nanoc3::Routers::NoDirsTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_path_for_root_page_rep
    # Create no-dirs router
    router = Nanoc3::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get page
    page = Nanoc3::Page.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/'
    )
    page_rep = Nanoc3::PageRep.new(page, :default)

    # Check
    assert_equal('/home.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_page_rep_with_default_rep
    # Create no-dirs router
    router = Nanoc3::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get page
    page = Nanoc3::Page.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/foo/'
    )
    page_rep = Nanoc3::PageRep.new(page, :default)

    # Check
    assert_equal('/foo.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_page_rep_with_custom_rep
    # Create no-dirs router
    router = Nanoc3::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get page
    page = Nanoc3::Page.new(
      'some content',
      {
        :filename => 'home',
        :extension => 'htm'
      },
      '/foo/'
    )
    page_rep = Nanoc3::PageRep.new(page, :raw)

    # Check
    assert_equal('/foo-raw.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_asset_rep_with_default_rep
    # Create site
    site = mock
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create default router
    router = Nanoc3::Routers::Default.new(site)

    # Get asset
    asset = Nanoc3::Asset.new(
      nil,
      { :extension => 'png' },
      '/foo/'
    )
    asset_rep = Nanoc3::AssetRep.new(asset, :default)

    # Check
    assert_equal('/imuhgez/foo.png', router.path_for_asset_rep(asset_rep))
  end

  def test_path_for_asset_rep_with_custom_rep
    # Create site
    site = mock
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create default router
    router = Nanoc3::Routers::Default.new(site)

    # Get asset
    asset = Nanoc3::Asset.new(
      nil,
      { :extension => 'png' },
      '/foo/'
    )
    asset_rep = Nanoc3::AssetRep.new(asset, :raw)

    # Check
    assert_equal('/imuhgez/foo-raw.png', router.path_for_asset_rep(asset_rep))
  end

end
