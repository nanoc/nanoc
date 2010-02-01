# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  class SampleFilesystemDataSource < Nanoc3::DataSource
    include Nanoc3::DataSources::Filesystem
  end

  def test_setup
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Remove files to make sure they are recreated
    FileUtils.rm_rf('content')
    FileUtils.rm_rf('layouts/default')
    FileUtils.rm_rf('lib/default.rb')

    # Mock VCS
    vcs = mock
    vcs.expects(:add).times(3) # One time for each directory
    data_source.vcs = vcs

    # Recreate files
    data_source.setup

    # Ensure essential files have been recreated
    assert(File.directory?('content/'))
    assert(File.directory?('layouts/'))
    assert(File.directory?('lib/'))

    # Ensure no non-essential files have been recreated
    assert(!File.file?('content/index.html'))
    assert(!File.file?('layouts/default.html'))
    assert(!File.file?('lib/default.rb'))
  end

  def test_items
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:load_objects).with('content', 'item', Nanoc3::Item)
    data_source.items
  end

  def test_layouts
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:load_objects).with('layouts', 'layout', Nanoc3::Layout)
    data_source.layouts
  end

  def test_create_item
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:create_object).with('content', 'the content', 'the attributes', 'the identifier')
    data_source.create_item('the content', 'the attributes', 'the identifier')
  end

  def test_create_layout
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:create_object).with('layouts', 'the content', 'the attributes', 'the identifier')
    data_source.create_layout('the content', 'the attributes', 'the identifier')
  end

end
