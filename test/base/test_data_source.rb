# encoding: utf-8

class Nanoc::DataSourceTest < Nanoc::TestCase
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

    # Test methods - loading data
    assert_equal [],  data_source.items
    assert_equal [],  data_source.layouts
  end

  def test_new_item
    data_source = Nanoc::DataSource.new(nil, nil, nil, nil)

    item = data_source.new_item('stuff', { title: 'Stuff!' }, '/asdf/')
    assert_equal 'stuff', item.raw_content
    assert_equal 'Stuff!', item.attributes[:title]
    assert_equal Nanoc::Identifier.new('/asdf/'), item.identifier
  end

  def test_new_layout
    data_source = Nanoc::DataSource.new(nil, nil, nil, nil)

    layout = data_source.new_layout('stuff', { title: 'Stuff!' }, '/asdf/')
    assert_equal 'stuff', layout.raw_content
    assert_equal 'Stuff!', layout.attributes[:title]
    assert_equal Nanoc::Identifier.new('/asdf/'), layout.identifier
  end
end
