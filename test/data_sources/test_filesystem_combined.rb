require 'test/helper'

class Nanoc::DataSources::FilesystemCombinedTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  # Test preparation

  def test_setup
    in_dir %w{ tmp } do
      # Create site
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))

        # Remove files
        FileUtils.rm_rf('asset_defaults.yaml')
        FileUtils.rm_rf('content')
        FileUtils.rm_rf('meta.yaml')
        FileUtils.rm_rf('page_defaults.yaml')
        FileUtils.rm_rf('layouts/default')
        FileUtils.rm_rf('lib/default.rb')

        # Convert site to filesystem_combined
        open('config.yaml', 'w') { |io| io.write('data_source: filesystem_combined') }

        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))

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
        assert(!File.file?('asset_defaults.yaml'))
        assert(!File.file?('content/index.html'))
        assert(!File.file?('layouts/default.html'))
        assert(!File.file?('meta.yaml'))
        assert(!File.file?('page_defaults.yaml'))
        assert(!File.file?('lib/default.rb'))
      end
    end
  end

  def test_destroy
    with_temp_site('filesystem_combined') do |site|
      # Mock VCS
      vcs = mock
      vcs.expects(:remove).times(6) # One time for each directory
      site.data_source.vcs = vcs

      # Destroy
      site.data_source.destroy
    end
  end

  def test_update
    # TODO implement
  end

  # Test pages

  def test_pages
    with_temp_site('filesystem_combined') do |site|
      assert_equal(1, site.pages.size)

      assert_equal('Home', site.pages[0].attribute_named(:title))
    end
  end

  def test_save_page
    # TODO implement
  end

  def test_move_page
    # TODO implement
  end

  def test_delete_page
    # TODO implement
  end

  # Test page defaults

  def test_page_defaults
    with_temp_site('filesystem_combined') do |site|
      assert_equal('html', site.page_defaults.attributes[:extension])
    end
  end

  def test_save_page_defaults
    # TODO implement
  end

  # Test assets

  def test_assets
    with_temp_site('filesystem_combined') do |site|
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

  def test_save_asset
    # TODO implement
  end

  def test_move_asset
    # TODO implement
  end

  def test_delete_asset
    # TODO implement
  end

  # Test asset defaults

  def test_asset_defaults
    with_temp_site('filesystem_combined') do |site|
      assert_equal([], site.asset_defaults.attributes[:filters])
    end
  end

  def test_save_asset_defaults
    # TODO implement
  end

  # Test layouts

  def test_layouts
    with_temp_site('filesystem_combined') do |site|
      layout = site.layouts[0]

      assert_equal('/default/', layout.path)
      assert_equal('erb', layout.attribute_named(:filter))
      assert(layout.content.include?('<%= @page.title %></title>'))
    end
  end

  def test_save_layout
    # TODO implement
  end

  def test_move_layout
    # TODO implement
  end

  def test_delete_layout
    # TODO implement
  end

  # Test code

  def test_code
    with_temp_site('filesystem_combined') do |site|
      assert_match(/# All files in the 'lib' directory will be loaded/, site.code.data)
    end
  end

  def test_save_code
    # TODO implement
  end

  # Test private methods

  def test_files_without_recursion
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil)

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
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil)

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

  def test_parse_file
    # TODO implement
  end

  # Miscellaneous

  def test_compile_site_with_file_object
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.read('output/index.html').include?("This page was last modified at #{File.new('content/index.txt').mtime}."))
    end
  end

  def test_compile_site_with_backup_files
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      begin
        File.open('content/index.txt~',   'w') { |io| }
        File.open('layouts/default.erb~', 'w') { |io| }

        site.compiler.run
        site.compiler.run

        assert_equal(2, site.pages.size)
        assert_equal(1, site.layouts.size)
      ensure
        FileUtils.rm_rf 'content/index.txt~' if File.exist?('content/index.txt~')
        FileUtils.rm_rf 'layouts/default.erb~' if File.exist?('layouts/default.erb~')
      end
    end
  end

end
