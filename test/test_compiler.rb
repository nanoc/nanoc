require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class CompileTest < Test::Unit::TestCase
  def setup
    $quiet = true
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp'
    Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure f }
    $quiet = false
  end

  def test_compile_empty_site
    with_fixture 'empty_site' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert Dir["output/*"].size == 1
      assert File.file?('output/index.html')
      assert !File.file?('output/moo/index.html')
    end
  end

  def test_compile_site_with_one_page
    with_fixture 'site_with_one_page' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert Dir["output/*"].size == 2
      assert File.file?('output/index.html')
      assert File.file?('output/moo/index.html')
    end
  end

  def test_compile_site_with_nested_layouts
    with_fixture 'site_with_nested_layouts' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert Dir["output/*"].size == 1
      assert File.file?('output/index.html')
      assert_match(/This is the default layout/, File.read('output/index.html'))
      assert_match(/This is the page layout/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_custom_paths
    with_fixture 'site_with_custom_paths' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert Dir["output/*"].size == 2
      assert File.file?('output/index.html')
      assert File.file?('output/bar.html')
      assert !File.file?('output/foo/index.html')
      assert !File.file?('output/bar/index.html')
    end
  end

  def test_compile_site_with_custom_extensions
    with_fixture 'site_with_custom_extensions' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert Dir["output/*"].size == 1
      assert !File.file?('output/index.html')
      assert File.file?('output/index.xhtml')
    end
  end

  def test_compile_site_with_custom_orders
    with_fixture 'site_with_custom_order' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert File.file?('output/index.html')
      assert File.file?('output/page_with_lower_order/index.html')
      assert_match(/1 pages/, File.read('output/index.html'))
      assert_match(/0 pages/, File.read('output/page_with_lower_order/index.html'))
    end
  end

  def test_compile_site_with_custom_output_dir
    with_fixture 'site_with_custom_output_dir' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert !File.file?('output/index.html')
      assert File.file?('tmp/custom_output/index.html')

      FileUtils.remove_entry_secure 'tmp'
    end
  end

  def test_compile_site_with_cool_content_file_names
    with_fixture 'site_with_cool_content_file_names' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert Dir["output/*"].size == 2
      assert File.file?('output/index.html')
      assert File.file?('output/about/index.html')
    end
  end

  def test_compile_site_with_draft_pages
    with_fixture 'site_with_draft_pages' do
      assert_nothing_raised { Nanoc::Compiler.new.run }

      assert Dir["output/*"].size == 1
      assert File.file?('output/index.html')
      assert !File.file?('output/about/index.html')
    end
  end

  def test_compile_site_with_backup_files
    with_fixture 'site_with_backup_files' do
      assert_nothing_raised { Nanoc::Compiler.new.run }
    end
  end

  def test_compile_site_with_double_extensions
    with_fixture 'site_with_double_extensions' do
      assert_nothing_raised { Nanoc::Compiler.new.run }
      assert File.file?('output/index.html')
      assert Dir["output/*"].size == 1
    end
  end

  def test_compile_site_with_no_layout
    with_fixture 'site_with_no_layout' do
      assert_nothing_raised { Nanoc::Compiler.new.run }
      assert File.file?('output/index.html')
      assert Dir["output/*"].size == 1
      assert_match(/This is a page without layout/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_assets
    with_fixture 'site_with_assets' do
      assert_nothing_raised { Nanoc::Compiler.new.run }
      assert File.file?('output/index.html')
      assert File.file?('output/style.css')
      assert Dir["output/*"].size == 2
      assert_match('body { background: #f00; }', File.read('output/style.css'))
    end
  end

  def test_compile_outside_site
    in_dir %w{ tmp } do
      assert_raise SystemExit do
        Nanoc::Compiler.new.run
      end
    end
  end

  def test_compile_newly_created_site
    in_dir %w{ tmp } do
      Nanoc::Creator.create_site('site')
      in_dir %w{ site } do
        Nanoc::Compiler.new.run

        assert Dir["output/*"].size == 1
        assert File.file?('output/index.html')
      end
    end
  end

  def test_compile_site_with_cooler_file_names
    with_fixture 'site_with_cooler_file_names' do
      assert_nothing_raised { Nanoc::Compiler.new.run }
      assert File.file?('output/index.html')
      assert File.file?('output/about/index.html')
      assert !File.file?('output/index/index.html')
      assert Dir["output/*"].size == 2
    end
  end

  def test_compile_site_with_bad_eruby_in_content
    with_fixture 'site_with_bad_eruby_in_content' do
      assert_raise SystemExit do
        Nanoc::Compiler.new.run
      end
    end
  end

  def test_compile_site_with_bad_eruby_in_layout
    with_fixture 'site_with_bad_eruby_in_layout' do
      assert_raise SystemExit do
        Nanoc::Compiler.new.run
      end
    end
  end
end
