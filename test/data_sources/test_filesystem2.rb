require 'helper'

class Nanoc::DataSources::Filesystem2Test < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  # Test preparation

  def test_setup
    in_dir %w{ tmp } do
      create_site('site')
      in_dir %w{ site } do
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))

        # Remove files

        FileUtils.remove_entry_secure('content/content.txt')
        FileUtils.remove_entry_secure('content/content.yaml')

        FileUtils.remove_entry_secure('meta.yaml')

        FileUtils.remove_entry_secure('templates/default/default.txt')
        FileUtils.remove_entry_secure('templates/default/default.yaml')

        FileUtils.remove_entry_secure('layouts/default/default.erb')
        FileUtils.remove_entry_secure('layouts/default/default.yaml')

        FileUtils.remove_entry_secure('lib/default.rb')

        # Convert site to filesystem2

        open('config.yaml', 'w') { |io| io.write('data_source: filesystem2') }

        # Setup site

        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.data_source.loading { site.data_source.setup {} }

        # Check whether files have been recreated

        assert(File.directory?('content/'))
        assert(File.file?('content/index.txt'))

        assert(File.file?('meta.yaml'))

        assert(File.directory?('templates/'))
        assert(File.file?('templates/default.txt'))

        assert(File.directory?('layouts/'))
        assert(File.file?('layouts/default.erb'))

        assert(File.directory?('lib/'))
        assert(File.file?('lib/default.rb'))
      end
    end
  end

  def test_update
    # TODO implement
  end

  # Test pages

  def test_pages
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.load_data

      assert_nothing_raised do
        assert_equal(2, site.pages.size)

        pages = site.pages.sort_by { |page| page.attribute_named(:title) }

        assert_equal('About', pages[0].attribute_named(:title))
        assert_equal('Home', pages[1].attribute_named(:title))
      end
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
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.load_data

      assert_nothing_raised do
        assert_equal('html', site.page_defaults.attributes[:extension])
      end
    end
  end

  def test_save_page_defaults
    # TODO implement
  end

  # Test templates

  def test_templates
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.load_data

      assert_nothing_raised do
        # FIXME test fails because reconstructing metadata is no longer possible
        # assert_equal(
        #   [
        #     {
        #       :name       => 'default',
        #       :content    => "This is a new page. Please edit me!",
        #       :meta       => "# Built-in\n\n# Custom\ntitle: A New Page",
        #       :extension  => '.txt'
        #     }
        #   ],
        #   site.templates
        # )
      end
    end
  end

  def test_save_template
    # TODO implement
  end

  def test_move_template
    # TODO implement
  end

  def test_delete_template
    # TODO implement
  end

  # Test layouts

  def test_layouts
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.load_data

      assert_nothing_raised do
        layout = site.layouts[0]

        assert_equal('/default/', layout.path)
        assert_equal('erb', layout.attribute_named(:filter))
        assert(layout.content.include?('<title><%= @page.title %></title>'))
      end
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
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.load_data
  
      assert_nothing_raised do
        assert_match(/# All files in the 'lib' directory will be loaded/, site.code.data)
      end
    end
  end

  def test_save_code
    # TODO implement
  end

  # Test private methods

  def test_files
  end

  def test_parse_file
  end

  def test_hash_to_yaml
  end

  # Test creating data

  # FIXME outdated, remove
  def test_create_page
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.load_data

      assert_nothing_raised do
        begin
          assert_nothing_raised()   { create_page('test1') }
          assert_raise(SystemExit)  { create_page('test1') }
          assert(File.file?('content/test1.txt'))

          assert_nothing_raised()   { create_page('test2/sub') }
          assert_raise(SystemExit)  { create_page('test2/sub') }
          assert(File.file?('content/test2/sub.txt'))

          site.load_data(true)

          assert_equal(4, site.pages.size)
          assert(site.pages.any? { |page| page.path == '/test1/' })
          assert(site.pages.any? { |page| page.path == '/test2/sub/' })
        ensure
          FileUtils.remove_entry_secure('content/test1.txt')
          FileUtils.remove_entry_secure('content/test2')
        end
      end
    end
  end

  # FIXME outdated, remove
  def test_create_template
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.load_data

      assert_nothing_raised do
        begin
          assert_nothing_raised()   { create_template('test1') }
          assert_raise(SystemExit)  { create_template('test1') }
          assert(File.file?('templates/test1.txt'))

          site.load_data(true)

          assert_equal(2, site.templates.size)
          assert(site.templates.any? { |template| template[:name] == 'test1' })
        ensure
          FileUtils.remove_entry_secure('templates/test1.txt')
        end
      end
    end
  end

  # FIXME outdated, remove
  def test_create_layout
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      site.load_data

      assert_nothing_raised do
        begin
          assert_nothing_raised()   { create_layout('test1') }
          assert_raise(SystemExit)  { create_layout('test1') }
          assert(File.file?('layouts/test1.erb'))

          site.load_data(true)

          assert_equal(2, site.layouts.size)
          assert(site.layouts.any? { |layout| layout.path == '/test1/' })
        ensure
          FileUtils.remove_entry_secure('layouts/test1.erb')
        end
      end
    end
  end

  # Miscellaneous

  def test_compile_site_with_file_object
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      assert_nothing_raised() { site.compiler.run }
      assert_nothing_raised() { site.compiler.run }

      assert(File.read('output/index.html').include?("This page was last modified at #{File.new('content/index.txt').mtime}."))
    end
  end

  def test_compile_site_with_backup_files
    with_site_fixture 'site_with_filesystem2_data_source' do |site|
      begin
        File.open('content/index.txt~',   'w') { |io| }
        File.open('layouts/default.erb~', 'w') { |io| }

        assert_nothing_raised() { site.compiler.run }
        assert_nothing_raised() { site.compiler.run }

        assert_equal(2, site.pages.size)
        assert_equal(1, site.layouts.size)
      ensure
        FileUtils.remove_entry_secure 'content/index.txt~' if File.exist?('content/index.txt~')
        FileUtils.remove_entry_secure 'layouts/default.erb~' if File.exist?('layouts/default.erb~')
      end
    end
  end

  def test_compile_outdated_site
    # Threshold for mtimes in which files will be considered the same
    threshold = 2.0

    in_dir %w{ tmp } do
      create_site('site')

      in_dir %w{ site } do
        # Remove files
        FileUtils.remove_entry_secure('content/content.txt')
        FileUtils.remove_entry_secure('content/content.yaml')
        FileUtils.remove_entry_secure('meta.yaml')
        FileUtils.remove_entry_secure('templates/default/default.txt')
        FileUtils.remove_entry_secure('templates/default/default.yaml')
        FileUtils.remove_entry_secure('layouts/default/default.erb')
        FileUtils.remove_entry_secure('layouts/default/default.yaml')
        FileUtils.remove_entry_secure('lib/default.rb')

        # Convert site to filesystem2
        open('config.yaml', 'w') { |io| io.write('data_source: filesystem2') }

        # Setup site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.data_source.loading { site.data_source.setup {} }

        # Get timestamps
        distant_past = Time.parse('1992-10-14')
        recent_past  = Time.parse('1998-05-18')
        now          = Time.now

        ########## INITIAL OUTPUT FILE GENERATION

        # Compile
        site.load_data(true)
        assert_nothing_raised() { site.compiler.run }

        ########## EVERYTHING UP TO DATE

        # Update file mtimes
        File.utime(distant_past, distant_past, 'layouts/default.erb')
        File.utime(distant_past, distant_past, 'content/index.txt')
        File.utime(distant_past, distant_past, 'meta.yaml')
        File.utime(distant_past, distant_past, 'lib/default.rb')
        File.utime(recent_past,  recent_past,  'output/index.html')

        # Compile
        site.load_data(true)
        assert_nothing_raised() { site.compiler.run }

        # Check compiled file's mtime (shouldn't have changed)
        assert((recent_past - File.new('output/index.html').mtime).abs < threshold)

        ########## RECENT PAGE

        # Update file mtimes
        File.utime(distant_past, distant_past, 'layouts/default.erb')
        File.utime(now,          now,          'content/index.txt')
        File.utime(distant_past, distant_past, 'meta.yaml')
        File.utime(distant_past, distant_past, 'lib/default.rb')
        File.utime(recent_past,  recent_past,  'output/index.html')

        # Compile
        site.load_data(true)
        assert_nothing_raised() { site.compiler.run }

        # Check compiled file's mtime (should be now)
        assert((now - File.new('output/index.html').mtime).abs < threshold)

        ########## RECENT LAYOUT

        # Update file mtimes
        File.utime(now,          now,          'layouts/default.erb')
        File.utime(distant_past, distant_past, 'content/index.txt')
        File.utime(distant_past, distant_past, 'meta.yaml')
        File.utime(distant_past, distant_past, 'lib/default.rb')
        File.utime(recent_past,  recent_past,  'output/index.html')

        # Compile
        site.load_data(true)
        assert_nothing_raised() { site.compiler.run }

        # Check compiled file's mtime (should be now)
        assert((now - File.new('output/index.html').mtime).abs < threshold)

        ########## RECENT PAGE DEFAULTS

        # Update file mtimes
        File.utime(distant_past, distant_past, 'layouts/default.erb')
        File.utime(distant_past, distant_past, 'content/index.txt')
        File.utime(now,          now,          'meta.yaml')
        File.utime(distant_past, distant_past, 'lib/default.rb')
        File.utime(recent_past,  recent_past,  'output/index.html')

        # Compile
        site.load_data(true)
        assert_nothing_raised() { site.compiler.run }

        # Check compiled file's mtime (should be now)
        assert((now - File.new('output/index.html').mtime).abs < threshold)

        ########## RECENT CODE

        # Update file mtimes
        File.utime(distant_past, distant_past, 'layouts/default.erb')
        File.utime(distant_past, distant_past, 'content/index.txt')
        File.utime(distant_past, distant_past, 'meta.yaml')
        File.utime(now,          now,          'lib/default.rb')
        File.utime(recent_past,  recent_past,  'output/index.html')

        # Compile
        site.load_data(true)
        assert_nothing_raised() { site.compiler.run }

        # Check compiled file's mtime (should be now)
        assert((now - File.new('output/index.html').mtime).abs < threshold)
      end
    end
  end

end
