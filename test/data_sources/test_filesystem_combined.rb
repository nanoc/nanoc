# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemCombinedTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  # Test preparation

  def test_setup
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

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

  # Test loading data

  def test_items
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Create foo item
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo.html', 'w') do |io|
      io.write("-----\n")
      io.write("title: Foo\n")
      io.write("-----\n")
      io.write("Lorem ipsum dolor sit amet...\n")
    end

    # Create bar item
    FileUtils.mkdir_p('content/bar')
    File.open('content/bar.html', 'w') do |io|
      io.write("-----\n")
      io.write("title: Bar\n")
      io.write("-----\n")
      io.write("Lorem ipsum dolor sit amet...\n")
    end

    # Load items
    items = data_source.items

    # Check items
    assert_equal(2, items.size)
    assert(items.any? { |a| a[:title] == 'Foo' })
    assert(items.any? { |a| a[:title] == 'Bar' })
  end

  def test_layouts
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Create layout
    FileUtils.mkdir_p('layouts')
    File.open('layouts/foo.html', 'w') do |io|
      io.write("-----\n")
      io.write("filter: erb\n")
      io.write("-----\n")
      io.write("Lorem ipsum dolor sit amet...\n")
    end

    # Load layouts
    layouts = data_source.layouts

    # Check layouts
    assert_equal(1,     layouts.size)
    assert_equal('erb', layouts[0][:filter])
  end

  def test_code
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Create code
    FileUtils.mkdir_p('lib')
    File.open('lib/foo.rb', 'w') do |io|
      io.write("# This is a bit of code right here...\n")
    end

    # Load code
    code = data_source.code

    # Check code
    assert_equal(
      [ { :code => "# This is a bit of code right here...\n", :filename => 'lib/foo.rb' } ],
      code.snippets
    )
  end

  def test_rules_with_valid_rules_file_names
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].each do |filename|
      begin
        # Create a sample rules file
        File.open(filename, 'w') { |io| io.write("This is #{filename}.") }
        
        # Attempt to read it
        assert_equal "This is #{filename}.", data_source.rules
      ensure
        FileUtils.rm(filename)
      end
    end
  end

  def test_rules_with_invalid_rules_file_names
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    begin
      # Create a sample rules file
      File.open('ZeRules', 'w') { |io| io.write("This is a rules file with an invalid name.") }

      # Attempt to read it
      assert_raises(Nanoc3::Errors::NoRulesFileFound) do
        data_source.rules
      end
    ensure
      FileUtils.rm('ZeRules')
    end
  end

  # Test creating data

  def test_create_item_at_root
    # Create item
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)
    data_source.create_item('content here', { :foo => 'bar' }, '/')

    # Check file existance
    assert File.directory?('content')
    assert !File.directory?('content/content')
    assert File.file?('content/index.html')

    # Check file content
    expected = "-----\n--- \nfoo: bar\n\n-----\ncontent here"
    assert_equal expected, File.read('content/index.html')
  end

  def test_create_item_not_at_root
    # Create item
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)
    data_source.create_item('content here', { :foo => 'bar' }, '/xxx/yyy/zzz/')

    # Check file existance
    assert File.directory?('content/xxx/yyy')
    assert !File.directory?('content/xxx/yyy/zzz')
    assert File.file?('content/xxx/yyy/zzz.html')
    assert !File.file?('content/xxx/yyy/zzz.yaml')

    # Check file content
    expected = "-----\n--- \nfoo: bar\n\n-----\ncontent here"
    assert_equal expected, File.read('content/xxx/yyy/zzz.html')
  end

  def test_create_layout
    # Create layout
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)
    data_source.create_layout('content here', { :foo => 'bar' }, '/xxx/yyy/zzz/')

    # Check file existance
    assert File.directory?('layouts/xxx/yyy')
    assert !File.directory?('layouts/xxx/yyy/zzz')
    assert File.file?('layouts/xxx/yyy/zzz.html')
    assert !File.file?('layouts/xxx/yyy/zzz.yaml')

    # Check file content
    expected = "-----\n--- \nfoo: bar\n\n-----\ncontent here"
    assert_equal expected, File.read('layouts/xxx/yyy/zzz.html')
  end

  # Test private methods

  def test_files_without_recursion
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo')
    FileUtils.mkdir_p('foo/a/b')
    File.open('foo/bar.html',       'w') { |io| io.write('test') }
    File.open('foo/baz.html',       'w') { |io| io.write('test') }
    File.open('foo/a/b/c.html',     'w') { |io| io.write('test') }
    File.open('foo/ugly.html~',     'w') { |io| io.write('test') }
    File.open('foo/ugly.html.orig', 'w') { |io| io.write('test') }
    File.open('foo/ugly.html.rej',  'w') { |io| io.write('test') }
    File.open('foo/ugly.html.bak',  'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      [ 'foo/bar.html', 'foo/baz.html' ],
      data_source.instance_eval do
        files('foo', false).sort
      end
    )
  end

  def test_files_with_recursion
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo')
    FileUtils.mkdir_p('foo/a/b')
    File.open('foo/bar.html',       'w') { |io| io.write('test') }
    File.open('foo/baz.html',       'w') { |io| io.write('test') }
    File.open('foo/a/b/c.html',     'w') { |io| io.write('test') }
    File.open('foo/ugly.html~',     'w') { |io| io.write('test') }
    File.open('foo/ugly.html.orig', 'w') { |io| io.write('test') }
    File.open('foo/ugly.html.rej',  'w') { |io| io.write('test') }
    File.open('foo/ugly.html.bak',  'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      [ 'foo/a/b/c.html', 'foo/bar.html', 'foo/baz.html' ],
      data_source.instance_eval do
        files('foo', true).sort
      end
    )
  end

  def test_parse_file_invalid
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Parse it
    assert_raises(RuntimeError) do
      data_source.instance_eval { parse_file('test.html', 'foobar') }
    end
  end

  def test_parse_file_full_meta
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "-----\n"
      io.write "foo: bar\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Parse it
    result = data_source.instance_eval { parse_file('test.html', 'foobar') }
    assert_equal({ 'foo' => 'bar' }, result[0])
    assert_equal('blah blah', result[1])
  end

  def test_parse_file_empty_meta
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "-----\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Parse it
    result = data_source.instance_eval { parse_file('test.html', 'foobar') }
    assert_equal({}, result[0])
    assert_equal('blah blah', result[1])
  end

end
