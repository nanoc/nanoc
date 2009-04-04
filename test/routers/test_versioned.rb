require 'test/helper'

class Nanoc::Routers::VersionedTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_path_for_page_rep_with_default_rep
    # Create versioned router
    router = Nanoc::Routers::Versioned.new(nil)

    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Get page
    page = Nanoc::Page.new(
      'some content',
      {
        :filename   => 'home',
        :extension  => 'htm',
        :version    => 123
      },
      '/foo/'
    )
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Check
    assert_equal('/foo/home.htm', router.path_for_page_rep(page_rep))
  end

  def test_path_for_page_rep_with_custom_rep
    # Create versioned router
    router = Nanoc::Routers::Versioned.new(nil)

    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Get page
    page = Nanoc::Page.new(
      'some content',
      {
        :reps => {
          :raw => {
            :filename   => 'home',
            :extension  => 'htm',
            :version    => 123
          }
        }
      },
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

    # Create versioned router
    router = Nanoc::Routers::Versioned.new(site)

    # Get asset
    asset = Nanoc::Asset.new(
      nil,
      {
        :extension => 'png',
        :version => 123
      },
      '/foo/'
    )
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps[0]

    # Check
    assert_equal(
      '/imuhgez/foo-v123.png',
      router.path_for_asset_rep(asset_rep)
    )
  end

  def test_path_for_asset_rep_with_custom_rep
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).at_least_once.returns(asset_defaults)
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create versioned router
    router = Nanoc::Routers::Versioned.new(site)

    # Get asset
    asset = Nanoc::Asset.new(
      nil,
      {
        :reps => {
          :raw => {
            :extension => 'png', 
            :version => 123
          }
        }
      },
      '/foo/'
    )
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps.find { |r| r.name == :raw }

    # Check
    assert_equal(
      '/imuhgez/foo-v123-raw.png',
      router.path_for_asset_rep(asset_rep)
    )
  end

  def test_path_for_asset_rep_with_default_rep_without_version
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).at_least_once.returns(asset_defaults)
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create versioned router
    router = Nanoc::Routers::Versioned.new(site)

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
    assert_equal(
      '/imuhgez/foo.png',
      router.path_for_asset_rep(asset_rep)
    )
  end

  def test_path_for_asset_rep_with_custom_rep_without_version
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).at_least_once.returns(asset_defaults)
    site.expects(:config).returns({ :assets_prefix => '/imuhgez' })

    # Create versioned router
    router = Nanoc::Routers::Versioned.new(site)

    # Get asset
    asset = Nanoc::Asset.new(
      nil,
      {
        :reps => {
          :raw => {
            :extension => 'png'
          }
        }
      },
      '/foo/'
    )
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps.find { |r| r.name == :raw }

    # Check
    assert_equal(
      '/imuhgez/foo-raw.png',
      router.path_for_asset_rep(asset_rep)
    )
  end

end
