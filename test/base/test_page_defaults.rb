require 'test/helper'

class Nanoc::PageDefaultsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_save
    # Create site
    site = mock

    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new({ :foo => 'bar' })
    page_defaults.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:save_page_defaults).with(page_defaults)

    # Save
    page_defaults.save
  end

end
