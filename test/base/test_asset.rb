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

  def test_compile
    # TODO implement
  end

end
