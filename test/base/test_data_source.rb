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

end
