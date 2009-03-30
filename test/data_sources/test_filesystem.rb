require 'test/helper'

class Nanoc3::DataSources::FilesystemTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  # Test preparation

  def test_setup
    in_dir %w{ tmp } do
      # Create site
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc3::Site.new(YAML.load_file('config.yaml'))

        # Remove files to make sure they are recreated
        FileUtils.rm_rf('assets')
        FileUtils.rm_rf('content')
        FileUtils.rm_rf('layouts/default')
        FileUtils.rm_rf('lib/default.rb')

        # Mock VCS
        vcs = mock
        vcs.expects(:add).times(4) # One time for each directory
        site.data_source.vcs = vcs

        # Recreate files
        site.data_source.loading { site.data_source.setup {} }

        # Ensure essential files have been recreated
        assert(File.directory?('assets/'))
        assert(File.directory?('content/'))
        assert(File.directory?('layouts/'))
        assert(File.directory?('lib/'))

        # Ensure no non-essential files have been recreated
        assert(!File.file?('content/content.html'))
        assert(!File.file?('content/content.yaml'))
        assert(!File.directory?('layouts/default/'))
        assert(!File.file?('lib/default.rb'))
      end
    end
  end

  # Test loading data

  def test_pages
    with_temp_site do |site|
      site.load_data

      assert_equal([ 'Home' ], site.pages.map { |page| page.attribute_named(:title) })
    end
  end

  def test_assets
    with_temp_site do |site|
      # Create asset with extension
      FileUtils.mkdir_p('assets/foo')
      File.open('assets/foo/foo.yaml', 'w') do |io|
        io.write("filters: []\n")
        io.write("extension: newfooext\n")
      end
      File.open('assets/foo/foo.fooext', 'w') do |io|
        io.write('Lorem ipsum dolor sit amet...')
      end

      # Create asset without extension
      FileUtils.mkdir_p('assets/bar')
      File.open('assets/bar/bar.yaml', 'w') do |io|
        io.write("filters: []\n")
      end
      File.open('assets/bar/bar.barext', 'w') do |io|
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
    with_temp_site do |site|
      site.load_data

      layout = site.layouts[0]

      assert_equal('/default/', layout.identifier)
      assert_equal('erb', layout.attribute_named(:filter))
      assert(layout.content.include?('<%= @page.title %></title>'))
    end
  end

  def test_code
    with_temp_site do |site|
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
      data_source = Nanoc3::DataSources::Filesystem.new(nil)
      data_source.create_page('content here', { :foo => 'bar' }, '/')

      # Check file existance
      assert File.directory?('content')
      assert File.file?('content/content.html')
      assert File.file?('content/content.yaml')

      # Check file content
      assert_equal 'content here', File.read('content/content.html')
      assert_match 'foo: bar',     File.read('content/content.yaml')
    end
  end

  def test_create_page_not_at_root
    in_dir 'tmp' do
      # Create page
      data_source = Nanoc3::DataSources::Filesystem.new(nil)
      data_source.create_page('content here', { :foo => 'bar' }, '/moo/')

      # Check file existance
      assert File.directory?('content/moo')
      assert File.file?('content/moo/moo.html')
      assert File.file?('content/moo/moo.yaml')

      # Check file content
      assert_equal 'content here', File.read('content/moo/moo.html')
      assert_match 'foo: bar',     File.read('content/moo/moo.yaml')
    end
  end

  def test_create_layout
    in_dir 'tmp' do
      # Create layout
      data_source = Nanoc3::DataSources::Filesystem.new(nil)
      data_source.create_layout('content here', { :foo => 'bar' }, '/moo/')

      # Check file existance
      assert File.directory?('layouts/moo')
      assert File.file?('layouts/moo/moo.html')
      assert File.file?('layouts/moo/moo.yaml')

      # Check file content
      assert_equal 'content here', File.read('layouts/moo/moo.html')
      assert_match 'foo: bar',     File.read('layouts/moo/moo.yaml')
    end
  end

  # Test private methods

  def test_meta_filenames
    # TODO implement
  end

  def test_content_filename_for_dir_with_one_content_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_two_content_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.xhtml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_raises(RuntimeError) do
      assert_equal(
        'tmp/foo/bar/baz/baz.html',
        data_source.instance_eval do
          content_filename_for_dir('tmp/foo/bar/baz')
        end
      )
    end
  end

  def test_content_filename_for_dir_with_one_content_and_one_meta_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.yaml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_content_and_many_meta_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.yaml', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/foo.yaml', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/zzz.yaml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_content_file_and_rejected_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.html~', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.html.orig', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.html.rej', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.html.bak', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_index_content_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/index.html', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/index.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  # Miscellaneous

  def test_meta_filenames_error
    # TODO implement
  end

  def test_content_filename_for_dir_error
    # TODO implement
  end

  def test_content_filename_for_dir_index_error
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/index')
    File.open('tmp/foo/index/index.html', 'w') { |io| io.write('test') }

    # Check
    assert_equal(
      'tmp/foo/index/index.html',
      data_source.instance_eval { content_filename_for_dir('tmp/foo/index') }
    )
  end

  def test_compile_huge_site
    with_temp_site do |site|
      # Create a lot of pages
      count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
      count.times do |i|
        FileUtils.mkdir("content/#{i}")
        File.open("content/#{i}/#{i}.html", 'w') { |io| io << "This is page #{i}." }
        File.open("content/#{i}/#{i}.yaml", 'w') { |io| io << "title: Page #{i}"   }
      end

      # Create rules
      File.open('Rules', 'w') do |io|
        io.write("page '*' do |p|\n")
        io.write("  p.write\n")
        io.write("end\n")
      end

      # Load and compile site
      site = Nanoc3::Site.new(YAML.load_file('config.yaml'))
      site.compiler.run
    end
  end

end
