require 'helper'

class DataSourceTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestingDataSource < Nanoc::DataSource

    attr_reader   :references
    attr_accessor :upped, :downed

    def up
      @upped = true
    end

    def down
      @downed = true
    end

  end

  def test_loading
    # Create data source
    data_source = TestingDataSource.new(nil)

    # Reset
    data_source.upped  = false
    data_source.downed = false

    # Check state
    assert_equal(0,     data_source.references)
    assert_equal(false, data_source.upped)
    assert_equal(false, data_source.downed)

    # Load
    data_source.loading do
      # Check state
      assert_equal(1,     data_source.references)
      assert_equal(true,  data_source.upped)
      assert_equal(false, data_source.downed)

      # Reset
      data_source.upped  = false
      data_source.downed = false

      # Load
      data_source.loading do
        # Check state
        assert_equal(2,     data_source.references)
        assert_equal(false, data_source.upped)
        assert_equal(false, data_source.downed)

        # Reset
        data_source.upped  = false
        data_source.downed = false
      end
    end

    # Check state
    assert_equal(0,     data_source.references)
    assert_equal(false, data_source.upped)
    assert_equal(true,  data_source.downed)
  end

  def test_not_implemented
    # Create data source
    data_source = TestingDataSource.new(nil)

    # Test optional methods
    assert_nothing_raised { data_source.up }
    assert_nothing_raised { data_source.down }

    # Test required methods - general
    assert_raise(NotImplementedError) { data_source.setup }

    # Test required methods - pages
    assert_raise(NotImplementedError) { data_source.pages }
    assert_raise(NotImplementedError) { data_source.save_page(nil) }
    assert_raise(NotImplementedError) { data_source.move_page(nil, nil) }
    assert_raise(NotImplementedError) { data_source.delete_page(nil) }

    # Test required methods - page defaults
    assert_raise(NotImplementedError) { data_source.page_defaults }
    assert_raise(NotImplementedError) { data_source.save_page_defaults(nil) }

    # Test required methods - layouts
    assert_raise(NotImplementedError) { data_source.layouts }
    assert_raise(NotImplementedError) { data_source.save_layout(nil) }
    assert_raise(NotImplementedError) { data_source.move_layout(nil, nil) }
    assert_raise(NotImplementedError) { data_source.delete_layout(nil) }

    # Test required methods - templates
    assert_raise(NotImplementedError) { data_source.templates }
    assert_raise(NotImplementedError) { data_source.save_template(nil) }
    assert_raise(NotImplementedError) { data_source.move_template(nil, nil) }
    assert_raise(NotImplementedError) { data_source.delete_template(nil) }

    # Test required methods - code
    assert_raise(NotImplementedError) { data_source.code }
    assert_raise(NotImplementedError) { data_source.save_code(nil) }
  end

end
