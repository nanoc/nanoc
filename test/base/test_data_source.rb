# encoding: utf-8

class Nanoc::DataSourceTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_loading
    # Create data source
    data_source = Nanoc::DataSource.new(nil, nil, nil, nil)
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
    data_source = Nanoc::DataSource.new(nil, nil, nil, nil)

    # Test optional methods
    data_source.up
    data_source.down
    data_source.update

    # Test required methods - general
    assert_raises(NotImplementedError) { data_source.setup }

    # Test methods - loading data
    assert_equal [],  data_source.items
    assert_equal [],  data_source.layouts

    # Test required method - creating data
    assert_raises(NotImplementedError) { data_source.create_item(nil, nil, nil) }
    assert_raises(NotImplementedError) { data_source.create_layout(nil, nil, nil) }
  end

end
