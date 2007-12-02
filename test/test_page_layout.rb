require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class PageLayoutTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_compile_site_with_no_layout
    with_site_fixture 'site_with_no_layout' do |site|
      assert_nothing_raised() { site.compile }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/This is a page without layout/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_nested_layouts
    with_site_fixture 'site_with_nested_layouts' do |site|
      assert_nothing_raised() { site.compile }
      assert_equal(1, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert_match(/This is the default layout/, File.read('output/index.html'))
      assert_match(/This is the page layout/, File.read('output/index.html'))
    end
  end

end
