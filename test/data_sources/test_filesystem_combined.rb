require 'test/helper'

class Nanoc3::DataSources::FilesystemCombinedTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  # Test preparation

  def test_setup
    in_dir %w{ tmp } do
      # Create site
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc3::Site.new(YAML.load_file('config.yaml'))

        # Remove files
        FileUtils.rm_rf('content')
        FileUtils.rm_rf('layouts/default')
        FileUtils.rm_rf('lib/default.rb')

        # Convert site to filesystem_combined
        open('config.yaml', 'w') { |io| io.write('data_source: filesystem_combined') }

        # Get site
        site = Nanoc3::Site.new(YAML.load_file('config.yaml'))

        # Mock VCS
        vcs = mock
        vcs.expects(:add).times(4) # One time for each directory
        site.data_source.vcs = vcs

        # Setup site
        site.data_source.loading { site.data_source.setup {} }

        # Ensure essential files have been recreated
        assert(File.directory?('content/'))
        assert(File.directory?('layouts/'))
        assert(File.directory?('lib/'))

        # Ensure no non-essential files have been recreated
        assert(!File.file?('content/index.html'))
        assert(!File.file?('layouts/default.html'))
        assert(!File.file?('lib/default.rb'))
      end
    end
  end

  def test_update
    # TODO implement
  end

  # Test loading data

  def test_pages
    with_temp_site('filesystem_combined') do |site|
      site.load_data

      assert_equal(1, site.pages.size)

      assert_equal('Home', site.pages[0].attribute_named(:title))
    end
  end

  def test_assets
    with_temp_site('filesystem_combined') do |site|
      site.load_data

      # Create asset with extension
      File.open('assets/foo.fooext', 'w') do |io|
        io.write("-----\n")
        io.write("filters: []\n")
        io.write("extension: newfooext\n")
        io.write("-----\n")
        io.write("Lorem ipsum dolor sit amet...")
      end

      # Create asset without extension
      File.open('assets/bar.barext', 'w') do |io|
        io.write("-----\n")
        io.write("filters: []\n")
        io.write("-----\n")
        io.write("Lorem ipsum dolor sit amet...")
      end

      # Reload data
      site.load_data(true)

      # Check assets
      assert_equal(2, site.assets.size)
      assert(site.assets.any? { |a| a.attribute_named(:extension) == 'newfooext' })
      assert(site.assets.any? { |a| a.attribute_named(:extension) == 'barext' })
    end
  end

  def test_layouts
    with_temp_site('filesystem_combined') do |site|
      site.load_data

      layout = site.layouts[0]

      assert_equal('/default/', layout.identifier)
      assert_equal('erb', layout.attribute_named(:filter))
      assert(layout.content.include?('<%= @page.title %></title>'))
    end
  end

  def test_code
    with_temp_site('filesystem_combined') do |site|
      site.load_data

      assert_match(
        /# All files in the 'lib' directory will be loaded/,
        site.code.snippets[0][:code]
      )
    end
  end

  # Test creating data

  def test_create_page_at_root
    in_dir 'tmp' do
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
  end

  def test_create_page_not_at_root
    in_dir 'tmp' do
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
  end

  def test_create_layout
    in_dir 'tmp' do
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
  end

  # Test private methods

  def test_files_without_recursion
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo')
    FileUtils.mkdir_p('tmp/foo/a/b')
    File.open('tmp/foo/bar.html',       'w') { |io| io.write('test') }
    File.open('tmp/foo/baz.html',       'w') { |io| io.write('test') }
    File.open('tmp/foo/a/b/c.html',     'w') { |io| io.write('test') }
    File.open('tmp/foo/ugly.html~',     'w') { |io| io.write('test') }
    File.open('tmp/foo/ugly.html.orig', 'w') { |io| io.write('test') }
    File.open('tmp/foo/ugly.html.rej',  'w') { |io| io.write('test') }
    File.open('tmp/foo/ugly.html.bak',  'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      [ 'tmp/foo/bar.html', 'tmp/foo/baz.html' ],
      data_source.instance_eval do
        files('tmp/foo', false).sort
      end
    )
  end

  def test_files_with_recursion
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo')
    FileUtils.mkdir_p('tmp/foo/a/b')
    File.open('tmp/foo/bar.html',       'w') { |io| io.write('test') }
    File.open('tmp/foo/baz.html',       'w') { |io| io.write('test') }
    File.open('tmp/foo/a/b/c.html',     'w') { |io| io.write('test') }
    File.open('tmp/foo/ugly.html~',     'w') { |io| io.write('test') }
    File.open('tmp/foo/ugly.html.orig', 'w') { |io| io.write('test') }
    File.open('tmp/foo/ugly.html.rej',  'w') { |io| io.write('test') }
    File.open('tmp/foo/ugly.html.bak',  'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      [ 'tmp/foo/a/b/c.html', 'tmp/foo/bar.html', 'tmp/foo/baz.html' ],
      data_source.instance_eval do
        files('tmp/foo', true).sort
      end
    )
  end

  def test_parse_file_invalid
    # Create a file
    File.open('tmp/test.html', 'w') do |io|
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Parse it
    assert_raises(RuntimeError) do
      data_source.instance_eval { parse_file('tmp/test.html', 'foobar') }
    end
  end

  def test_parse_file_full_meta
    # Create a file
    File.open('tmp/test.html', 'w') do |io|
      io.write "-----\n"
      io.write "foo: bar\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Parse it
    result = data_source.instance_eval { parse_file('tmp/test.html', 'foobar') }
    assert_equal({ 'foo' => 'bar' }, result[0])
    assert_equal('blah blah', result[1])
  end

  def test_parse_file_empty_meta
    # Create a file
    File.open('tmp/test.html', 'w') do |io|
      io.write "-----\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil)

    # Parse it
    result = data_source.instance_eval { parse_file('tmp/test.html', 'foobar') }
    assert_equal({}, result[0])
    assert_equal('blah blah', result[1])
  end

end
