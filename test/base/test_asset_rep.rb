require 'helper'

class Nanoc::AssetRepTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    asset = Nanoc::Asset.new(nil, { 'foo' => 'bar' }, '/foo/')
    asset.site = site

    # Get rep
    asset.build_reps
    asset_rep = asset.reps.first

    # Assert flags reset
    assert(asset_rep.instance_eval { !@compiled })
    assert(asset_rep.instance_eval { !@modified })
    assert(asset_rep.instance_eval { !@created })
    assert(asset_rep.instance_eval { !@filtered })
  end

  def test_to_proxy
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    asset = Nanoc::Asset.new(nil, { 'foo' => 'bar' }, '/foo/')
    asset.site = site

    # Get rep
    asset.build_reps
    asset_rep = asset.reps.first

    # Create proxy
    asset_rep_proxy = asset_rep.to_proxy

    # Check values
    assert_equal('bar', asset_rep_proxy.foo)
  end

  def test_created_modified_compiled
    # TODO implement
  end

  def test_outdated
    # TODO implement
  end

  def test_disk_and_web_path
    # TODO implement
  end

  def test_attribute_named_with_custom_rep
    # TODO implement
  end

  def test_attribute_named_with_default_rep
    # TODO implement
  end

  def test_compile
    # TODO implement
  end

  def test_compile_even_when_outdated
    # TODO implement
  end

  def test_compile_from_scratch
    # TODO implement
  end

  def test_digest
    # TODO implement
  end

  def test_compile_binary
    # TODO implement
  end

  def test_compile_textual
    # TODO implement
  end

end
