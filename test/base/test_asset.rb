require 'helper'

class Nanoc::AssetTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # TODO implement
  end

  def test_build_reps
    # TODO implement
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
    # TODO implement
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
