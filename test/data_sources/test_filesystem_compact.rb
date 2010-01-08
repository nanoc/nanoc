# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemCompactTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  # Test preparation

  def test_setup
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

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
    assert(!File.file?('content/content.html'))
    assert(!File.file?('content/content.yaml'))
    assert(!File.directory?('layouts/default/'))
    assert(!File.file?('lib/default.rb'))
  end

  # Test loading data

  def test_items_with_index_names
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Create
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/index.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo' }))
    end
    File.open('content/foo/index.html', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Load
    items = data_source.items

    # Check
    assert_equal 1, items.size
    assert_equal '/foo/', items[0].identifier
    assert_equal 'Foo',   items[0][:title]
    assert_equal 'html',  items[0][:extension]
  end

  def test_items_with_non_index_names
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Create
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/bar.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo' }))
    end
    File.open('content/foo/bar.html', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Load
    items = data_source.items

    # Check
    assert_equal 1, items.size
    assert_equal '/foo/bar/', items[0].identifier
    assert_equal 'Foo',       items[0][:title]
    assert_equal 'html',      items[0][:extension]
  end

  def test_items_with_period_in_name
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    FileUtils.mkdir_p('content/foo')

    # Create bar.css
    File.open('content/foo/bar.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo' }))
    end
    File.open('content/foo/bar.css', 'w') do |io|
      io.write('body{}')
    end

    # Create bar.baz.css
    File.open('content/foo/bar.baz.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo2' }))
    end
    File.open('content/foo/bar.baz.css', 'w') do |io|
      io.write('body{}')
    end

    # Load
    items = data_source.items.sort_by { |i| i[:title] }

    # Check
    assert_equal 2, items.size
    assert_equal '/foo/bar/',     items[0].identifier
    assert_equal 'Foo',           items[0][:title]
    assert_equal '/foo/bar.baz/', items[1].identifier
    assert_equal 'Foo2',          items[1][:title]
  end

  def test_items_with_both_index_and_non_index_names
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Prepare creating items
    FileUtils.mkdir_p('content/foo')

    # Create foo item
    File.open('content/foo/index.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo' }))
    end
    File.open('content/foo/index.xml', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Create bar item
    File.open('content/foo/bar.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Bar' }))
    end
    File.open('content/foo/bar.rhtml', 'w') do |io|
      io.write("Lorem ipsum dolor sit amet...")
    end

    # Load items
    items = data_source.items
    items = items.sort_by { |i| i[:title] }

    # Check items
    assert_equal 2, items.size
    assert_equal '/foo/bar/', items[0].identifier
    assert_equal 'Bar',       items[0][:title]
    assert_equal 'rhtml',     items[0][:extension]
    assert_equal '/foo/',     items[1].identifier
    assert_equal 'Foo',       items[1][:title]
    assert_equal 'xml',       items[1][:extension]
  end

  def test_layouts
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Create layout
    FileUtils.mkdir_p('layouts')
    File.open('layouts/foo.yaml', 'w') do |io|
      io.write(YAML.dump({ 'cat' => 'miaow' }))
    end
    File.open('layouts/foo.rhtml', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Load layouts
    layouts = data_source.layouts

    # Check layouts
    assert_equal 1,       layouts.size
    assert_equal 'miaow', layouts[0][:cat]
    assert_equal 'rhtml', layouts[0][:extension]
    assert_equal '/foo/', layouts[0].identifier
  end

  # Test creating data

  def test_create_item_at_level_0
    # Create item
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)
    data_source.create_item('content here', { :foo => 'bar' }, '/')

    # Check file existance
    assert File.directory?('content')
    assert File.file?('content/index.html')
    assert File.file?('content/index.yaml')

    # Check file content
    assert_equal 'content here', File.read('content/index.html')
    assert_match 'foo: bar',     File.read('content/index.yaml')
  end

  def test_create_item_at_level_1
    # Create item
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)
    data_source.create_item('content here', { :foo => 'bar' }, '/moo/')

    # Check file existance
    assert File.directory?('content')
    assert File.file?('content/moo.html')
    assert File.file?('content/moo.yaml')

    # Check file content
    assert_equal 'content here', File.read('content/moo.html')
    assert_match 'foo: bar',     File.read('content/moo.yaml')
  end

  def test_create_item_at_level_2
    # Create item
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)
    data_source.create_item('content here 4 sho', { :baz => 'qux' }, '/moo/baah/')

    # Check file existance
    assert File.directory?('content')
    assert File.file?('content/moo/baah.html')
    assert File.file?('content/moo/baah.yaml')

    # Check file content
    assert_equal 'content here 4 sho', File.read('content/moo/baah.html')
    assert_match 'baz: qux',           File.read('content/moo/baah.yaml')
  end

  def test_create_layout
    # Create layout
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)
    data_source.create_layout('content here', { :foo => 'bar' }, '/moo/')

    # Check file existance
    assert File.directory?('layouts')
    assert File.file?('layouts/moo.html')
    assert File.file?('layouts/moo.yaml')

    # Check file content
    assert_equal 'content here', File.read('layouts/moo.html')
    assert_match 'foo: bar',     File.read('layouts/moo.yaml')
  end

  # Test private methods

  def test_all_files_in
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Write sample files
    %w( foo.html foo.yaml bar.entry.html qux.yaml ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Get all files
    output_expected = {
      './foo'       => [ 'yaml', 'html' ],
      './bar.entry' => [ nil,    'html' ],
      './qux'       => [ 'yaml', nil    ]
    }
    output_actual = data_source.send :all_files_in, '.'

    # Check
    assert_equal output_expected, output_actual
  end

  def test_all_files_in_with_multiple_content_files
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Write sample files
    %w( foo.html foo.xhtml foo.txt foo.yaml bar.html qux.yaml ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Check
    assert_raises RuntimeError do
      data_source.send :all_files_in, '.'
    end
  end

  def test_all_files_in_with_backup_files
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Write sample files
    %w( foo.html foo.html~ foo.yaml foo.yaml~ foo.html.bak foo.yaml.bak bar.html qux.yaml ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Get all files
    output_expected = {
      './foo' => [ 'yaml', 'html' ],
      './bar' => [ nil,    'html' ],
      './qux' => [ 'yaml', nil    ]
    }
    output_actual = data_source.send :all_files_in, '.'

    # Check
    assert_equal output_expected, output_actual
  end

  def test_identifier_for_filename_with_same_name
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '/foo/foo/', data_source.send(:identifier_for_filename, '/foo/foo.yaml')
  end

  def test_identifier_for_filename_with_other_name
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '/foo/bar/', data_source.send(:identifier_for_filename, '/foo/bar.yaml')
  end

  def test_identifier_for_filename_with_index_name
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '/foo/', data_source.send(:identifier_for_filename, '/foo/index.yaml')
  end

  def test_identifier_for_filename_with_content_name
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '/foo/bar/', data_source.send(:identifier_for_filename, '/foo/bar.html')
  end

  def test_identifier_for_filename_with_multiple_extensions
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '/foo/bar.html/', data_source.send(:identifier_for_filename, '/foo/bar.html.erb')
  end

  def test_basename_of_without_extensions
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '/foo/bar', data_source.send(:basename_of, '/foo/bar')
  end

  def test_identifier_for_filename_with_subfilename
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo')
    File.open('foo/bar.yaml',         'w') { |io| io.write('test') }
    File.open('foo/bar.html',         'w') { |io| io.write('test') }
    File.open('foo/quxbar.yaml',      'w') { |io| io.write('test') }
    File.open('foo/quxbar.html',      'w') { |io| io.write('test') }
    File.open('foo/barqux.yaml',      'w') { |io| io.write('test') }
    File.open('foo/barqux.html',      'w') { |io| io.write('test') }
    File.open('foo/quxbarqux.yaml',   'w') { |io| io.write('test') }
    File.open('foo/quxbarqux.html',   'w') { |io| io.write('test') }
    File.open('foo/qux.bar.yaml',     'w') { |io| io.write('test') }
    File.open('foo/qux.bar.html',     'w') { |io| io.write('test') }
    File.open('foo/bar.qux.yaml',     'w') { |io| io.write('test') }
    File.open('foo/bar.qux.html',     'w') { |io| io.write('test') }
    File.open('foo/qux.bar.qux.yaml', 'w') { |io| io.write('test') }
    File.open('foo/qux.bar.qux.html', 'w') { |io| io.write('test') }

    # Check content filename
    {
      'foo/bar.yaml'         => '/foo/bar/',
      'foo/quxbar.yaml'      => '/foo/quxbar/',
      'foo/barqux.yaml'      => '/foo/barqux/',
      'foo/quxbarqux.yaml'   => '/foo/quxbarqux/',
      'foo/qux.bar.yaml'     => '/foo/qux.bar/',
      'foo/bar.qux.yaml'     => '/foo/bar.qux/',
      'foo/qux.bar.qux.yaml' => '/foo/qux.bar.qux/'
    }.each_pair do |meta_filename, expected_identifier|
      assert_equal(
        expected_identifier,
        data_source.instance_eval { identifier_for_filename(meta_filename) }
      )
    end
  end

  def test_basename_of_with_one_extension
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '/foo/bar', data_source.send(:basename_of, '/foo/bar.html')
  end

  def test_basename_of_with_absolute_path
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '/foo/bar.html', data_source.send(:basename_of, '/foo/bar.html.erb')
  end

  def test_basename_of_with_relative_path
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal 'foo/bar.html', data_source.send(:basename_of, 'foo/bar.html.erb')
  end

  def test_ext_of_without_extension
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '', data_source.send(:ext_of, '/foo/bar')
  end

  def test_ext_of_with_one_extension
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '.html', data_source.send(:ext_of, '/foo/bar.html')
  end

  def test_ext_of_with_multiple_extensions
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Check
    assert_equal '.erb', data_source.send(:ext_of, '/foo/bar.html.erb')
  end

  # Miscellaneous

  def test_meta_filenames_error
    # TODO implement
  end

  def test_content_filename_for_dir_error
    # TODO implement
  end

  def test_compile_huge_site
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Create a lot of items
    count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
    count.times do |i|
      FileUtils.mkdir_p("content/#{i}")
      File.open("content/#{i}/#{i}.html", 'w') { |io| io << "This is item #{i}." }
      File.open("content/#{i}/#{i}.yaml", 'w') { |io| io << "title: Item #{i}"   }
    end

    # Read all items
    data_source.items
  end

end
