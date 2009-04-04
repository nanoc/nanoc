require 'test/helper'

class Nanoc::DataSourceTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_loading
    # Create data source
    data_source = Nanoc::DataSource.new(nil)
    data_source.expects(:up).times(1)
    data_source.expects(:down).times(1)

    # Test nested loading
    assert_equal(0, data_source.instance_eval { @references })
    data_source.loading do
      assert_equal(1, data_source.instance_eval { @references })
      data_source.loading do
        assert_equal(2, data_source.instance_eval { @references })
      end
      assert_equal(1, data_source.instance_eval { @references })
    end
    assert_equal(0, data_source.instance_eval { @references })
  end

  def test_not_implemented
    # Create data source
    data_source = Nanoc::DataSource.new(nil)

    # Test optional methods
    data_source.up
    data_source.down
    data_source.update

    # Test required methods - general
    assert_raises(NotImplementedError) { data_source.setup }
    assert_raises(NotImplementedError) { data_source.destroy }

    # Test required methods - pages
    assert_raises(NotImplementedError) { data_source.pages }
    assert_raises(NotImplementedError) { data_source.save_page(nil) }
    assert_raises(NotImplementedError) { data_source.move_page(nil, nil) }
    assert_raises(NotImplementedError) { data_source.delete_page(nil) }

    # Test required methods - page defaults
    assert_raises(NotImplementedError) { data_source.page_defaults }
    assert_raises(NotImplementedError) { data_source.save_page_defaults(nil) }

    # Test required methods - assets
    assert_raises(NotImplementedError) { data_source.assets }
    assert_raises(NotImplementedError) { data_source.save_asset(nil) }
    assert_raises(NotImplementedError) { data_source.move_asset(nil, nil) }
    assert_raises(NotImplementedError) { data_source.delete_asset(nil) }

    # Test required methods - asset defaults
    assert_raises(NotImplementedError) { data_source.asset_defaults }
    assert_raises(NotImplementedError) { data_source.save_asset_defaults(nil) }

    # Test required methods - layouts
    assert_raises(NotImplementedError) { data_source.layouts }
    assert_raises(NotImplementedError) { data_source.save_layout(nil) }
    assert_raises(NotImplementedError) { data_source.move_layout(nil, nil) }
    assert_raises(NotImplementedError) { data_source.delete_layout(nil) }

    # Test required methods - templates
    assert_raises(NotImplementedError) { data_source.templates }
    assert_raises(NotImplementedError) { data_source.save_template(nil) }
    assert_raises(NotImplementedError) { data_source.move_template(nil, nil) }
    assert_raises(NotImplementedError) { data_source.delete_template(nil) }

    # Test required methods - code
    assert_raises(NotImplementedError) { data_source.code }
    assert_raises(NotImplementedError) { data_source.save_code(nil) }
  end

end
