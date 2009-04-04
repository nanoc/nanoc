require 'test/helper'

class Nanoc::AssetRepProxyTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_get
    # Get asset
    asset = mock
    asset.expects(:attribute_named).with(:moo).returns('asset attr moo')

    # Get asset proxy
    asset_proxy = Nanoc::AssetProxy.new(asset)
    asset.expects(:to_proxy).returns(asset_proxy)

    # Get asset rep
    asset_rep = mock
    asset_rep.expects(:name).returns('asset rep name')
    asset_rep.expects(:asset).returns(asset)
    asset_rep.expects(:web_path).returns('asset rep web path')
    asset_rep.expects(:attribute_named).times(2).with(:blah).returns('asset rep attr blah')
    asset_rep.expects(:attribute_named).with(:'blah!').returns('asset rep attr blah!')

    # Get asset proxy
    asset_rep_proxy = Nanoc::AssetRepProxy.new(asset_rep)

    # Test
    assert_equal('asset rep name',        asset_rep_proxy.name)
    assert_equal('asset attr moo',        asset_rep_proxy.asset.moo)
    assert_equal('asset rep web path',    asset_rep_proxy.path)
    assert_equal('asset rep attr blah',   asset_rep_proxy.blah)
    assert_equal('asset rep attr blah',   asset_rep_proxy.blah?)
    assert_equal('asset rep attr blah!',  asset_rep_proxy.blah!)
  end

end
