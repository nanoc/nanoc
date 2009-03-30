require 'helper'

class Nanoc::OldCompilerTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_compile_site_with_one_page
    with_site_fixture 'site_with_one_page' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(2, Dir[File.join('output', '*')].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/moo/index.html'))
    end
  end

  def test_compile_site_with_custom_paths
    with_site_fixture 'site_with_custom_paths' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(2, Dir[File.join('output', '*')].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/bar.html'))
      assert(!File.file?('output/foo/index.html'))
      assert(!File.file?('output/bar/index.html'))
      assert_match(/\/bar.html/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_custom_extensions
    with_site_fixture 'site_with_custom_extensions' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(1, Dir[File.join('output', '*')].size)
      assert(!File.file?('output/index.html'))
      assert(File.file?('output/index.xhtml'))
    end
  end

  def test_compile_site_with_custom_output_dir
    with_site_fixture 'site_with_custom_output_dir' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(0, Dir[File.join('output', '*')].size)
      assert(!File.file?('output/index.html'))

      assert_equal(1, Dir[File.join('tmp', 'custom_output', '*')].size)
      assert(File.file?('tmp/custom_output/index.html'))

      FileUtils.rm_rf 'tmp' if File.exist?('tmp')
    end
  end

  def test_compile_site_with_cool_content_file_names
    with_site_fixture 'site_with_cool_content_file_names' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(2, Dir[File.join('output', '*')].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/about/index.html'))
    end
  end

  def test_compile_site_with_draft_pages
    with_site_fixture 'site_with_draft_pages' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(1, Dir[File.join('output', '*')].size)
      assert(File.file?('output/index.html'))
      assert(!File.file?('output/about/index.html'))
    end
  end

  def test_compile_site_with_double_extensions
    with_site_fixture 'site_with_double_extensions' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
    end
  end

  def test_compile_site_with_page_dot_notation
    with_site_fixture 'site_with_page_dot_notation' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
      assert_match(/<title>Foobar<\/title>/, File.read('output/index.html'))
      assert_match(/This page is called "Foobar"/, File.read('output/index.html'))
      assert_match(/ya rly/, File.read('output/index.html'))
      assert_match(/This page rocks./, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_page_id_links
    with_site_fixture 'site_with_page_id_links' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert(File.file?('output/about/index.html'))
      assert(File.file?('output/blog/index.html'))
      assert_equal(3, Dir[File.join('output', '*')].size)
      assert_match(/<a href="\/">home page<\/a>/, File.read('output/about/index.html'))
      assert_match(/<a href="\/blog\/">blog<\/a>/, File.read('output/about/index.html'))
    end
  end

  def test_compile_site_with_non_outputed_pages
    with_site_fixture 'site_with_non_outputed_pages' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert(!File.file?('output/hidden/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
    end
  end

  def test_compile_site_with_custom_filename
    with_site_fixture 'site_with_custom_filename' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/default.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
    end
  end

  def test_compile_site_with_circular_dependencies
    with_site_fixture 'site_with_circular_dependencies' do |site|
      assert_raise(Nanoc::Errors::RecursiveCompilationError) { site.compiler.run }
    end
  end

  def test_compile_site_with_parent_children_links
    with_site_fixture 'site_with_parent_children_links' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert(File.file?('output/foo/index.html'))
      assert_equal(2, Dir[File.join('output', '*')].size)

      assert_match(/The children of this page are: Foo./, File.read('output/index.html'))
      assert_match(/This page does not have a parent/, File.read('output/index.html'))

      assert_match(/The title of this page's parent page is A New Root Page./, File.read('output/foo/index.html'))
      assert_match(/This page does not have any children/, File.read('output/foo/index.html'))
    end
  end

  def test_compile_site_with_content_from_other_page
    with_site_fixture 'site_with_content_from_other_page' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert(File.file?('output/foo/index.html'))
      assert_equal(2, Dir[File.join('output', '*')].size)

      assert_match(/<p>The content of foo is <q>Hi, I'm the Foo page.<\/q>.<\/p>/, File.read('output/index.html'))
    end
  end

  def test_compile_newly_created_site
    in_dir %w{ tmp } do
      create_site('tmp_site')
      in_dir %w{ tmp_site } do
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        assert(site)
        site.compiler.run
        site.compiler.run

        assert_equal(1, Dir[File.join('output', '*')].size)
        assert(File.file?('output/index.html'))
      end
    end
  end

end
