require 'test/helper'

class Nanoc::AssetTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Make sure attributes are cleaned
    asset = Nanoc::Asset.new(nil, { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, asset.attributes)

    # Make sure path is fixed
    asset = Nanoc::Asset.new(nil, { 'foo' => 'bar' }, 'foo')
    assert_equal('/foo/', asset.path)
  end

  def test_build_reps_impl_asset_impl_asset_defaults
    # Create asset defaults
    asset_defaults = mock
    asset_defaults.expects(:attributes).returns({})

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    asset = Nanoc::Asset.new(nil, { :foo => 'bar' }, '/foo/')
    asset.site = site
    asset.build_reps

    # Check
    assert_equal(1, asset.reps.size)
    assert_equal(:default, asset.reps[0].name)
  end

  def test_build_reps_impl_asset_expl_asset_defaults
    # Create asset defaults
    asset_defaults = mock
    asset_defaults.expects(:attributes).returns({
      :reps => {
        :default => {},
        :raw => {}
      }
    })

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    asset = Nanoc::Asset.new(nil, { :foo => 'bar' }, '/foo/')
    asset.site = site
    asset.build_reps

    # Check
    assert_equal(2, asset.reps.size)
    assert(asset.reps.any? { |r| r.name == :default })
    assert(asset.reps.any? { |r| r.name == :raw })
  end

  def test_build_reps_expl_asset_impl_asset_defaults
    # Create asset defaults
    asset_defaults = mock
    asset_defaults.expects(:attributes).returns({})

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    reps = { :default => {}, :raw => {} }
    asset = Nanoc::Asset.new(nil, { :reps => reps }, '/foo/')
    asset.site = site
    asset.build_reps

    # Check
    assert_equal(2, asset.reps.size)
    assert(asset.reps.any? { |r| r.name == :default })
    assert(asset.reps.any? { |r| r.name == :raw })
  end

  def test_build_reps_expl_asset_expl_asset_defaults
    # Create asset defaults
    asset_defaults = mock
    asset_defaults.expects(:attributes).returns({
      :reps => {
        :default => {},
        :raw => {}
      }
    })

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    reps = { :default => {}, :something => {} }
    asset = Nanoc::Asset.new(nil, { :reps => reps }, '/foo/')
    asset.site = site
    asset.build_reps

    # Check
    assert_equal(3, asset.reps.size)
    assert(asset.reps.any? { |r| r.name == :default })
    assert(asset.reps.any? { |r| r.name == :raw })
    assert(asset.reps.any? { |r| r.name == :something })
  end

  def test_build_reps_expl_asset_expl_asset_defaults_no_default
    # Create asset defaults
    asset_defaults = mock
    asset_defaults.expects(:attributes).returns({
      :reps => {
        :foo => {},
        :bar => {}
      }
    })

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    reps = { :baz => {}, :quux => {} }
    asset = Nanoc::Asset.new(nil, { :reps => reps }, '/foo/')
    asset.site = site
    asset.build_reps

    # Check
    assert_equal(5, asset.reps.size)
    assert(asset.reps.any? { |r| r.name == :default })
  end

  def test_to_proxy
    # Create asset
    asset = Nanoc::Asset.new(nil, { 'foo' => 'bar' }, '/foo/')

    # Create proxy
    asset_proxy = asset.to_proxy

    # Check values
    assert_equal('bar', asset_proxy.foo)
  end

  def test_attribute_named
    in_dir [ 'tmp' ] do
      # Create temporary site
      create_site('testing')

      in_dir [ 'testing' ] do
        # Get site
        site = Nanoc::Site.new({})

        # Create asset defaults (hacky...)
        asset_defaults = Nanoc::AssetDefaults.new({ :quux => 'stfu' })
        site.instance_eval { @asset_defaults = asset_defaults }

        # Create asset
        asset = Nanoc::Asset.new("content", { 'foo' => 'bar' }, '/foo/')
        asset.site = site

        # Test
        assert_equal('bar',  asset.attribute_named(:foo))
        assert_equal('dat',  asset.attribute_named(:extension))
        assert_equal('stfu', asset.attribute_named(:quux))

        # Create asset
        asset = Nanoc::Asset.new("content", { 'extension' => 'png' }, '/foo/')
        asset.site = site

        # Test
        assert_equal(nil,    asset.attribute_named(:foo))
        assert_equal('png',  asset.attribute_named(:extension))
        assert_equal('stfu', asset.attribute_named(:quux))
      end
    end
  end

  def test_save
    # Create site
    site = mock

    # Create asset
    asset = Nanoc::Asset.new("content", { :attr => 'ibutes' }, '/path/')
    asset.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:save_asset).with(asset)

    # Save
    asset.save
  end

  def test_move_to
    # Create site
    site = mock

    # Create asset
    asset = Nanoc::Asset.new("content", { :attr => 'ibutes' }, '/path/')
    asset.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:move_asset).with(asset, '/new_path/')

    # Move
    asset.move_to('/new_path/')
  end

  def test_delete
    # Create site
    site = mock

    # Create asset
    asset = Nanoc::Asset.new("content", { :attr => 'ibutes' }, '/path/')
    asset.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:delete_asset).with(asset)

    # Delete
    asset.delete
  end

end
