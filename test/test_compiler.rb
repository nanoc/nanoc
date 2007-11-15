require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class CompilerTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')
    Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure f if File.exist?(f)}
    $quiet = false
  end

  def test_compile_empty_site
    with_site_fixture 'empty_site' do |site|
      assert_nothing_raised() { site.compile! }
      assert_equal(1, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(!File.file?('output/moo/index.html'))
    end
  end

  def test_compile_site_with_one_page
    with_site_fixture 'site_with_one_page' do |site|
      assert_nothing_raised() { site.compile! }
      assert_equal(2, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/moo/index.html'))
    end
  end

  def test_compile_site_with_custom_paths
    with_site_fixture 'site_with_custom_paths' do |site|
      assert_nothing_raised() { site.compile! }

      assert_equal(2, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/bar.html'))
      assert(!File.file?('output/foo/index.html'))
      assert(!File.file?('output/bar/index.html'))
    end
  end

  def test_compile_site_with_custom_extensions
    with_site_fixture 'site_with_custom_extensions' do |site|
      assert_nothing_raised() { site.compile! }

      assert_equal(1, Dir["output/*"].size)
      assert(!File.file?('output/index.html'))
      assert(File.file?('output/index.xhtml'))
    end
  end

  def test_compile_site_with_custom_output_dir
    with_site_fixture 'site_with_custom_output_dir' do |site|
      assert_nothing_raised() { site.compile! }

      assert_equal(0, Dir["output/*"].size)
      assert(!File.file?('output/index.html'))

      assert_equal(1, Dir["tmp/custom_output/*"].size)
      assert(File.file?('tmp/custom_output/index.html'))

      FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')
    end
  end

  def test_compile_site_with_cool_content_file_names
    with_site_fixture 'site_with_cool_content_file_names' do |site|
      assert_nothing_raised() { site.compile! }

      assert_equal(2, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/about/index.html'))
    end
  end

  def test_compile_site_with_draft_pages
    with_site_fixture 'site_with_draft_pages' do |site|
      assert_nothing_raised() { site.compile! }

      assert_equal(1, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(!File.file?('output/about/index.html'))
    end
  end

  def test_compile_site_with_backup_files
    with_site_fixture 'site_with_backup_files' do |site|
      FileManager.create_file('content/content.txt~') { '' }
      FileManager.create_file('layouts/default.erb~') { '' }
      assert_nothing_raised() { site.compile! }
      FileUtils.remove_entry_secure 'content/content.txt~' if File.exist?('content/content.txt~')
      FileUtils.remove_entry_secure 'layouts/default.erb~' if File.exist?('layouts/default.erb~')
    end
  end

  def test_compile_site_with_double_extensions
    with_site_fixture 'site_with_double_extensions' do |site|
      assert_nothing_raised() { site.compile! }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
    end
  end

  def test_compile_site_with_page_dot_notation
    with_site_fixture 'site_with_page_dot_notation' do |site|
      assert_nothing_raised() { site.compile! }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/<title>Foobar<\/title>/, File.read('output/index.html'))
      assert_match(/This page is called "Foobar"/, File.read('output/index.html'))
      assert_match(/ya rly/, File.read('output/index.html'))
      assert_match(/This page rocks./, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_page_id_links
    with_site_fixture 'site_with_page_id_links' do |site|
      assert_nothing_raised() { site.compile! }
      assert(File.file?('output/index.html'))
      assert(File.file?('output/about/index.html'))
      assert(File.file?('output/blog/index.html'))
      assert_equal(3, Dir["output/*"].size)
      assert_match(/<a href="\/">home page<\/a>/, File.read('output/about/index.html'))
      assert_match(/<a href="\/blog\/">blog<\/a>/, File.read('output/about/index.html'))
    end
  end

  def test_compile_site_with_non_outputed_pages
    with_site_fixture 'site_with_non_outputed_pages' do |site|
      assert_nothing_raised() { site.compile! }
      assert(File.file?('output/index.html'))
      assert(!File.file?('output/hidden/index.html'))
      assert_equal(1, Dir["output/*"].size)
    end
  end

  def test_compile_site_with_custom_filename
    with_site_fixture 'site_with_custom_filename' do |site|
      assert_nothing_raised() { site.compile! }
      assert(File.file?('output/default.html'))
      assert_equal(1, Dir["output/*"].size)
    end
  end

  def test_compile_site_with_circular_dependencies
    with_site_fixture 'site_with_circular_dependencies' do |site|
      assert_raise(SystemExit) { site.compile! }
    end
  end

  def test_compile_outside_site
    in_dir %w{ tmp } do
      assert(Nanoc::Site.from_cwd.nil?)
    end
  end

  def test_compile_newly_created_site
    in_dir %w{ tmp } do
      $nanoc_creator.create_site('tmp_site')
      in_dir %w{ tmp_site } do
        site = Nanoc::Site.from_cwd
        assert(site)
        assert_nothing_raised() { site.compile! }

        assert_equal(1, Dir["output/*"].size)
        assert(File.file?('output/index.html'))
      end
      FileUtils.remove_entry_secure 'tmp_site' if File.exist?('tmp')
    end
  end

end
