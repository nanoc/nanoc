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
        site = Nanoc::Site.from_cwd

        # Remove files to make sure they are recreated

        FileUtils.remove_entry_secure('pages/index.txt')
        FileUtils.remove_entry_secure('pages/meta.yaml')

        FileUtils.remove_entry_secure('meta.yaml')

        FileUtils.remove_entry_secure('templates/default/default.txt')
        FileUtils.remove_entry_secure('templates/default/default.yaml')

        FileUtils.remove_entry_secure('layouts/default.erb')

        FileUtils.remove_entry_secure('lib/default.rb')

        # Recreate files

        site.setup

        # Check whether files have been recreated

        assert(File.directory?('pages'))
        assert(!File.directory?('content'))
        assert(File.file?('pages/index.txt'))
        assert(File.file?('pages/meta.yaml'))

        assert(File.file?('meta.yaml'))

        assert(File.directory?('templates/'))
        assert(File.directory?('templates/default/'))
        assert(File.file?('templates/default/default.txt'))
        assert(File.file?('templates/default/default.yaml'))

        assert(File.directory?('layouts/'))
        assert(File.file?('layouts/default.erb'))

        assert(File.directory?('lib/'))
        assert(File.file?('lib/default.rb'))
      end
    end
  end

  # Test loading data

  def test_pages_with_old_pages_dir_name
    with_site_fixture 'empty_site' do |site|
      site.load_data

      assert_nothing_raised do
        assert_equal([ 'My New Homepage' ], site.pages.map { |page| page.attribute_named(:title) })
      end
    end
  end

  def test_pages_with_new_pages_dir_name
    with_site_fixture 'site_with_new_pages_dir_name' do |site|
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
        assert_equal(
          [
            {
              :name       => 'default',
              :content    => "<html>\n" +
                             "  <head>\n" +
                             "    <title><%= @page[:title] %></title>\n" +
                             "  </head>\n" +
                             "  <body>\n" +
                             "<%= @page[:content] %>\n" +
                             "  </body>\n" +
                             "</html>\n",
              :extension  => '.erb'
            }
          ],
          site.layouts
        )
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
        site = Nanoc::Site.from_cwd

        assert_nothing_raised()   { site.create_page('test') }
        assert_raise(SystemExit)  { site.create_page('test') }

        assert_nothing_raised()   { site.create_page('foo/bar') }
        assert_raise(SystemExit)  { site.create_page('foo/bar') }

        assert(!File.directory?('content'))

        assert(File.directory?('pages/test'))
        assert(File.file?('pages/test/test.txt'))
        assert(File.file?('pages/test/test.yaml'))

        assert(File.directory?('pages/foo/bar'))
        assert(File.file?('pages/foo/bar/bar.txt'))
        assert(File.file?('pages/foo/bar/bar.yaml'))
      end
    end
  end

  def test_create_template
    in_dir %w{ tmp } do
      Nanoc::Site.create('site')
      in_dir %w{ site }  do
        site = Nanoc::Site.from_cwd

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
        site = Nanoc::Site.from_cwd

        assert_nothing_raised()   { site.create_layout('test') }
        assert_raise(SystemExit)  { site.create_layout('test') }

        assert(File.file?('layouts/test.erb'))
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

end
