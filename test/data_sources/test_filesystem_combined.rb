require 'test/helper'

class Nanoc3::DataSources::FilesystemCombinedTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  # Test preparation

  def test_setup
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Remove files to make sure they are recreated
    FileUtils.rm_rf('assets')
    FileUtils.rm_rf('content')
    FileUtils.rm_rf('layouts/default')
    FileUtils.rm_rf('lib/default.rb')

    # Mock VCS
    vcs = mock
    vcs.expects(:add).times(4) # One time for each directory
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

  def test_update
    # TODO implement
  end

  # Test loading data

  def test_pages
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Create foo page
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo.yaml', 'w') do |io|
      io.write("-----\n")
      io.write("title: Foo\n")
      io.write("-----\n")
      io.write("Lorem ipsum dolor sit amet...\n")
    end

    # Create bar page
    FileUtils.mkdir_p('content/bar')
    File.open('content/bar.yaml', 'w') do |io|
      io.write("-----\n")
      io.write("title: Bar\n")
      io.write("-----\n")
      io.write("Lorem ipsum dolor sit amet...\n")
    end

    # Load pages
    pages = data_source.pages

    # Check pages
    assert_equal(2, pages.size)
    assert(pages.any? { |a| a.attribute_named(:title) == 'Foo' })
    assert(pages.any? { |a| a.attribute_named(:title) == 'Bar' })
  end

  def test_assets
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Create asset with extension
    FileUtils.mkdir_p('assets')
    File.open('assets/foo.fooext', 'w') do |io|
      io.write("-----\n")
      io.write("filters: []\n")
      io.write("extension: newfooext\n")
      io.write("-----\n")
      io.write("Lorem ipsum dolor sit amet...\n")
    end

    # Create asset without extension
    FileUtils.mkdir_p('assets')
    File.open('assets/bar.barext', 'w') do |io|
      io.write("-----\n")
      io.write("filters: []\n")
      io.write("-----\n")
      io.write("Lorem ipsum dolor sit amet...\n")
    end

    # Load assets
    assets = data_source.assets

    # Check assets
    assert_equal(2, assets.size)
    assert(assets.any? { |a| a.attribute_named(:extension) == 'newfooext' })
    assert(assets.any? { |a| a.attribute_named(:extension) == 'barext' })
  end

  def test_layouts
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Create layout
    FileUtils.mkdir_p('layouts')
    File.open('layouts/foo.yaml', 'w') do |io|
      io.write("-----\n")
      io.write("filter: erb\n")
      io.write("-----\n")
      io.write("Lorem ipsum dolor sit amet...\n")
    end

    # Load layouts
    layouts = data_source.layouts

    # Check layouts
    assert_equal(1,     layouts.size)
    assert_equal('erb', layouts[0].attribute_named(:filter))
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

  # Test creating data

  def test_create_page_at_root
    # Create page
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)
    data_source.create_page('content here', { :foo => 'bar' }, '/')

    # Check file existance
    assert File.directory?('content')
    assert !File.directory?('content/content')
    assert File.file?('content/index.html')

    # Check file content
    expected = "-----\n--- \nfoo: bar\n\n-----\ncontent here"
    assert_equal expected, File.read('content/index.html')
  end

  def test_create_page_not_at_root
    # Create page
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)
    data_source.create_page('content here', { :foo => 'bar' }, '/xxx/yyy/zzz/')

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
