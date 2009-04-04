require 'test/helper'

class Nanoc::AssetDefaultsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_save
    # Create site
    site = mock

    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new({ :foo => 'bar' })
    asset_defaults.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:save_asset_defaults).with(asset_defaults)

    # Save
    asset_defaults.save
  end

end
