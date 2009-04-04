require 'test/helper'

class Nanoc::OldPageFilterTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_compile_site_with_filters
    with_site_fixture 'site_with_filters' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(2, Dir[File.join('output', '*')].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/foo/index.html'))
      assert_match(/This is Sparta./, File.read('output/index.html'))
      assert_match(/This is Sparta./, File.read('output/foo/index.html'))
    end
  end

  def test_compile_site_with_custom_filters
    with_site_fixture 'site_with_custom_filters' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
      assert_match(/nanoc rocks/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_post_filters
    with_site_fixture 'site_with_post_filters' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
      assert_match(/<p>First pass<\/p>/, File.read('output/index.html'))
      assert_match(/<p>Second pass<\/p>/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_layouts_variable
    with_site_fixture 'site_with_layouts_variable' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
      assert(File.read('output/index.html').include?('<p>The cool layouts are /bar/, /foo/.</p>'))
    end
  end

end
