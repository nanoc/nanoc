require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class PageFilterTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')
    Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure f if File.exist?(f)}
    $quiet = false
  end

  def test_compile_site_with_filters
    with_site_fixture 'site_with_filters' do |site|
      assert_nothing_raised() { site.compile! }
      assert_equal(2, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/foo/index.html'))
      assert_match(/This is Sparta./, File.read('output/index.html'))
      assert_match(/This is Sparta./, File.read('output/foo/index.html'))
    end
  end

  def test_compile_site_with_custom_filters
    with_site_fixture 'site_with_custom_filters' do |site|
      assert_nothing_raised() { site.compile! }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/nanoc rocks/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_post_filters
    with_site_fixture 'site_with_post_filters' do |site|
      assert_nothing_raised() { site.compile! }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/<p>First pass<\/p>/, File.read('output/index.html'))
      assert_match(/<p>Second pass<\/p>/, File.read('output/index.html'))
    end
  end

end
