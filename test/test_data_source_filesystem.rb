require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class DataSourceFilesystemTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  # Test preparation

  def test_setup
    in_dir %w{ tmp } do
      Nanoc::Site.create('site')
      in_dir %w{ site } do
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))

        # Remove files to make sure they are recreated

        FileUtils.remove_entry_secure('content/content.txt')
        FileUtils.remove_entry_secure('content/content.yaml')

        FileUtils.remove_entry_secure('meta.yaml')

        FileUtils.remove_entry_secure('templates/default/default.txt')
        FileUtils.remove_entry_secure('templates/default/default.yaml')

        FileUtils.remove_entry_secure('layouts/default/default.erb')
        FileUtils.remove_entry_secure('layouts/default/default.yaml')

        FileUtils.remove_entry_secure('lib/default.rb')

        # Recreate files

        site.setup

        # Check whether files have been recreated

        assert(File.directory?('content/'))
        assert(File.file?('content/content.txt'))
        assert(File.file?('content/content.yaml'))

        assert(File.file?('meta.yaml'))

        assert(File.directory?('templates/'))
        assert(File.directory?('templates/default/'))
        assert(File.file?('templates/default/default.txt'))
        assert(File.file?('templates/default/default.yaml'))

        assert(File.directory?('layouts/'))
        assert(File.directory?('layouts/default/'))
        assert(File.file?('layouts/default/default.erb'))
        assert(File.file?('layouts/default/default.yaml'))

        assert(File.directory?('lib/'))
        assert(File.file?('lib/default.rb'))
      end
    end
  end

  # Test loading data

  def test_pages
    with_site_fixture 'empty_site' do |site|
      site.load_data

      assert_nothing_raised do
        assert_equal([ 'My New Homepage' ], site.pages.map { |page| page.attribute_named(:title) })
      end
    end
  end

  def test_page_defaults
    with_site_fixture 'empty_site' do |site|
      site.load_data

      assert_nothing_raised do
        assert_equal('html', site.page_defaults[:extension])
      end
    end
  end

  def test_templates
    with_site_fixture 'empty_site' do |site|
      site.load_data

      assert_nothing_raised do
        assert_equal(
          [
            {
              :name       => 'default',
              :content    => "This is a new page. Please edit me!\n",
              :meta       => "# Built-in\n\n# Custom\ntitle: A New Page\n",
              :extension  => '.txt'
            }
          ],
          site.templates
        )
      end
    end
  end

  def test_layouts
    with_site_fixture 'empty_site' do |site|
      site.load_data

      assert_nothing_raised do
        layout = site.layouts[0]

        assert_equal('/default/', layout.path)
        assert_equal('.erb', layout.attribute_named(:extension))
        assert(layout.content.include?('<title><%= @page[:title] %></title>'))
      end
    end
  end

  def test_code
    with_site_fixture 'empty_site' do |site|
      site.load_data

      assert_nothing_raised do
        assert_match(/# All files in the 'lib' directory will be loaded/, site.code)
      end
    end
  end

  # Test creating data

  def test_create_page
    in_dir %w{ tmp } do
      Nanoc::Site.create('site')
      in_dir %w{ site } do
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))

        assert_nothing_raised()   { site.create_page('test') }
        assert_raise(SystemExit)  { site.create_page('test') }

        assert_nothing_raised()   { site.create_page('foo/bar') }
        assert_raise(SystemExit)  { site.create_page('foo/bar') }

        assert(File.directory?('content/test/'))
        assert(File.file?('content/test/test.txt'))
        assert(File.file?('content/test/test.yaml'))

        assert(File.directory?('content/foo/bar/'))
        assert(File.file?('content/foo/bar/bar.txt'))
        assert(File.file?('content/foo/bar/bar.yaml'))
      end
    end
  end

  def test_create_template
    in_dir %w{ tmp } do
      Nanoc::Site.create('site')
      in_dir %w{ site }  do
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))

        assert_nothing_raised()   { site.create_template('test') }
        assert_raise(SystemExit)  { site.create_template('test') }

        assert(File.directory?('templates/test/'))
        assert(File.file?('templates/test/test.txt'))
        assert(File.file?('templates/test/test.yaml'))
      end
    end
  end

  def test_create_layout
    in_dir %w{ tmp }  do
      Nanoc::Site.create('site')
      in_dir %w{ site }  do  
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))

        assert_nothing_raised()   { site.create_layout('test') }
        assert_raise(SystemExit)  { site.create_layout('test') }

        assert(File.file?('layouts/test/test.erb'))
        assert(File.file?('layouts/test/test.yaml'))
      end
    end
  end

  # Miscellaneous

  def test_compile_site_with_file_object
    with_site_fixture 'site_with_file_object' do |site|
      assert_nothing_raised() { site.compile }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert(File.read('output/index.html').include?("This page was last modified at #{File.new('content/content.erb').mtime}."))
    end
  end

  def test_compile_site_with_backup_files
    with_site_fixture 'site_with_backup_files' do |site|
      FileManager.create_file('content/content.txt~') { '' }
      FileManager.create_file('layouts/default.erb~') { '' }
      assert_nothing_raised() { site.compile }
      FileUtils.remove_entry_secure 'content/content.txt~' if File.exist?('content/content.txt~')
      FileUtils.remove_entry_secure 'layouts/default.erb~' if File.exist?('layouts/default.erb~')
    end
  end

  def test_compile_site_with_new_layout_structure
    with_site_fixture 'site_with_new_layout_structure' do |site|
      assert_nothing_raised() { site.compile }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert(File.read('output/index.html').include?('<div class="supercool">Blah blah blah this is a page blah blah blah.</div>'))
    end
  end

end
