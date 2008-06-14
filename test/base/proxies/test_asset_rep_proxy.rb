require 'helper'

class Nanoc::AssetRepProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestAssetRep

    attr_reader :asset

    def initialize(asset)
      @asset = asset
    end

    def to_proxy
      @proxy ||= Nanoc::AssetRepProxy.new(self)
    end

    def name
      :default
    end

    def web_path
      "asset rep web path"
    end

    def attribute_named(key)
      "asset rep attribute named #{key}"
    end

  end

  class TestAsset

    def to_proxy
      @proxy ||= Nanoc::AssetProxy.new(self)
    end

    def path
      'asset path'
    end

    def web_path
      'asset web path'
    end

    def attribute_named(key)
      "asset attribute named #{key}"
    end

    def reps
      @reps ||= [ TestAssetRep.new(self) ]
    end

  end

  def test_get
    # Get asset
    asset = TestAsset.new
    asset_rep = asset.reps[0]
    asset_rep_proxy = asset_rep.to_proxy

    # Test
    assert_equal('asset attribute named moo',       asset_rep_proxy.asset.moo)
    assert_equal('asset rep web path',              asset_rep_proxy.path)
    assert_equal('asset rep attribute named blah',  asset_rep_proxy.blah)
    assert_equal('asset rep attribute named blah',  asset_rep_proxy.blah?)
    assert_equal('asset rep attribute named blah!', asset_rep_proxy.blah!)
  end

end
