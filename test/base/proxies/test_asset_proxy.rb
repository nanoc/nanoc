require 'test/helper'

class Nanoc::AssetProxyTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_get
    # Get asset rep
    asset_rep = mock
    asset_rep.expects(:name).returns(:default)
    asset_rep.expects(:web_path).returns('asset rep web path')

    # Get asset
    asset = mock
    asset.expects(:reps).returns([ asset_rep ])
    asset.expects(:mtime).returns(Time.parse('2008-05-19'))
    asset.expects(:attribute_named).times(2).with(:blah).returns('asset attr blah')
    asset.expects(:attribute_named).with(:'blah!').returns('asset attr blah!')

    # Get asset proxy
    asset_proxy = Nanoc::AssetProxy.new(asset)

    # Test
    assert_equal('asset rep web path',      asset_proxy.path)
    assert_equal(Time.parse('2008-05-19'),  asset_proxy.mtime)
    assert_equal('asset attr blah',         asset_proxy.blah)
    assert_equal('asset attr blah',         asset_proxy.blah?)
    assert_equal('asset attr blah!',        asset_proxy.blah!)
  end

  def test_reps
    # Get asset reps
    asset_rep_0 = mock
    asset_rep_0.expects(:name).at_least_once.returns(:default)
    asset_rep_0.expects(:attribute_named).with(:foo).returns('bar')
    asset_rep_1 = mock
    asset_rep_1.expects(:name).at_least_once.returns(:raw)
    asset_rep_1.expects(:attribute_named).with(:baz).returns('quux')

    # Get asset reps proxies
    asset_rep_0_proxy = Nanoc::AssetRepProxy.new(asset_rep_0)
    asset_rep_0.expects(:to_proxy).returns(asset_rep_0_proxy)
    asset_rep_1_proxy = Nanoc::AssetRepProxy.new(asset_rep_1)
    asset_rep_1.expects(:to_proxy).returns(asset_rep_1_proxy)

    # Get asset
    asset = mock
    asset.expects(:reps).times(2).returns([ asset_rep_0, asset_rep_1 ])

    # Get asset proxy
    asset_proxy = Nanoc::AssetProxy.new(asset)

    # Test
    assert_equal('bar',  asset_proxy.reps(:default).foo)
    assert_equal('quux', asset_proxy.reps(:raw).baz)
  end

end
