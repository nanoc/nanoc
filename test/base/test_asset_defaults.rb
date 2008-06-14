require 'helper'

class Nanoc::AssetDefaultsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestDataSource

    attr_reader :save_called, :was_loaded

    def initialize
      @save_called  = false
      @references   = 0
      @was_loaded   = false
    end

    def loading
      # Load if necessary
      up if @references == 0
      @references += 1

      yield
    ensure
      # Unload if necessary
      @references -= 1
      down if @references == 0
    end

    def up
      @was_loaded = true
    end

    def down
    end

    def save_asset_defaults(asset_defaults)
      @save_called = true
    end

  end

  class TestSite

    def data_source
      @data_source ||= TestDataSource.new
    end

  end

  def test_save
    # Create site
    site = TestSite.new

    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new({ :foo => 'bar' })
    asset_defaults.site = site

    # Save
    assert(!site.data_source.save_called)
    assert(!site.data_source.was_loaded)
    asset_defaults.save
    assert(site.data_source.save_called)
    assert(site.data_source.was_loaded)
  end

end
