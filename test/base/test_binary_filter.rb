require 'helper'

class Nanoc::BinaryFilterTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestPageRep

    def to_proxy
      @proxy ||= Nanoc::Proxy.new(self)
    end

    def attribute_named(key)
      "page rep attribute named #{key}"
    end

  end

  class TestPage

    def to_proxy
      @proxy ||= Nanoc::Proxy.new(self)
    end

    def attribute_named(key)
      "page attribute named #{key}"
    end

    def reps
      @reps ||= [ TestPageRep.new ]
    end

  end

  class TestAssetRep

    def to_proxy
      @proxy ||= Nanoc::Proxy.new(self)
    end

    def attribute_named(key)
      "asset rep attribute named #{key}"
    end

  end

  class TestAsset

    def to_proxy
      @proxy ||= Nanoc::Proxy.new(self)
    end

    def attribute_named(key)
      "asset attribute named #{key}"
    end

    def reps
      @reps ||= [ TestAssetRep.new ]
    end

  end

  class TestLayout

    def to_proxy
      @proxy ||= Nanoc::Proxy.new(self)
    end

    def attribute_named(key)
      "layout attribute named #{key}"
    end

  end

  class TestSite

    attr_reader :pages, :assets, :layouts

    def config
      "Not a real config."
    end

    def initialize
      @pages   = [ TestPage.new   ]
      @assets  = [ TestAsset.new  ]
      @layouts = [ TestLayout.new ]
    end

  end

  def test_initialize
    # Create site and filter
    site      = TestSite.new
    asset_rep = site.assets[0].reps[0]
    asset     = site.assets[0]
    filter    = Nanoc::BinaryFilter.new(asset_rep, asset, site)

    # Make sure pages and assets are not proxied by the filter
    assert_equal(
      'asset attribute named foo',
      filter.instance_eval { @asset.to_proxy.foo }
    )
    assert_equal(
      'asset rep attribute named foo',
      filter.instance_eval { @asset_rep.to_proxy.foo }
    )

    # Make sure pages, assets and layouts are proxied
    assert_equal(
      'page attribute named foo',
      filter.instance_eval { @pages[0].foo }
    )
    assert_equal(
      'asset attribute named foo',
      filter.instance_eval { @assets[0].foo }
    )
    assert_equal(
      'layout attribute named foo',
      filter.instance_eval { @layouts[0].foo }
    )
  end

  def test_run
    # Create site and filter
    site      = TestSite.new
    asset_rep = site.assets[0].reps[0].to_proxy
    asset     = site.assets[0].to_proxy
    filter    = Nanoc::BinaryFilter.new(asset_rep, asset, site)

    # Make sure an error is raised
    assert_raise(NotImplementedError) do
      filter.run(nil)
    end
  end

end
