require 'helper'

class Nanoc::AssetProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestAssetRep

    def name
      :default
    end

    def web_path
      "asset rep web path"
    end

  end

  class TestAsset

    def path
      'asset path'
    end

    def mtime
      Time.parse('2008-05-19')
    end

    def web_path
      'asset web path'
    end

    def attribute_named(key)
      "attribute named #{key}"
    end

    def reps
      @reps ||= [ TestAssetRep.new ]
    end

  end

  def test_get
    # Get asset
    asset = TestAsset.new
    asset_proxy = Nanoc::AssetProxy.new(asset)

    # Test
    assert_equal('asset rep web path',      asset_proxy.path)
    assert_equal(Time.parse('2008-05-19'),  asset_proxy.mtime)
    assert_equal('attribute named blah',    asset_proxy.blah)
    assert_equal('attribute named blah',    asset_proxy.blah?)
    assert_equal('attribute named blah!',   asset_proxy.blah!)
  end

end
