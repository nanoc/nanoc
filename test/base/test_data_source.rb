# frozen_string_literal: true

require 'helper'

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
    assert_equal [], data_source.items
    assert_equal [], data_source.layouts
  end

  def test_new_item
    data_source = Nanoc::DataSource.new(nil, nil, nil, nil)

    item = data_source.new_item('stuff', { title: 'Stuff!' }, '/asdf/', checksum_data: 'abcdef')
    assert_equal 'stuff', item.content.string
    assert_equal 'Stuff!', item.attributes[:title]
    assert_equal Nanoc::Identifier.new('/asdf/'), item.identifier
    assert_equal 'abcdef', item.checksum_data
  end

  def test_new_item_with_checksums
    data_source = Nanoc::DataSource.new(nil, nil, nil, nil)

    item = data_source.new_item('stuff', { title: 'Stuff!' }, '/asdf/', content_checksum_data: 'con-cs', attributes_checksum_data: 'attr-cs')
    assert_equal 'stuff', item.content.string
    assert_equal 'Stuff!', item.attributes[:title]
    assert_equal Nanoc::Identifier.new('/asdf/'), item.identifier
    assert_equal 'con-cs', item.content_checksum_data
    assert_equal 'attr-cs', item.attributes_checksum_data
  end

  def test_new_layout
    data_source = Nanoc::DataSource.new(nil, nil, nil, nil)

    layout = data_source.new_layout('stuff', { title: 'Stuff!' }, '/asdf/', checksum_data: 'abcdef')
    assert_equal 'stuff', layout.content.string
    assert_equal 'Stuff!', layout.attributes[:title]
    assert_equal Nanoc::Identifier.new('/asdf/'), layout.identifier
    assert_equal 'abcdef', layout.checksum_data
  end

  def test_new_layout_with_checksums
    data_source = Nanoc::DataSource.new(nil, nil, nil, nil)

    layout = data_source.new_layout('stuff', { title: 'Stuff!' }, '/asdf/', content_checksum_data: 'con-cs', attributes_checksum_data: 'attr-cs')
    assert_equal 'stuff', layout.content.string
    assert_equal 'Stuff!', layout.attributes[:title]
    assert_equal Nanoc::Identifier.new('/asdf/'), layout.identifier
    assert_equal 'con-cs', layout.content_checksum_data
    assert_equal 'attr-cs', layout.attributes_checksum_data
  end
end
