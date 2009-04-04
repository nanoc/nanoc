require 'test/helper'

class Nanoc::OldPageLayoutTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_compile_site_with_no_layout
    with_site_fixture 'site_with_no_layout' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
      assert_match(/This is a page without layout/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_nested_layouts
    with_site_fixture 'site_with_nested_layouts' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(1, Dir[File.join('output', '*')].size)
      assert(File.file?('output/index.html'))
      assert_match(/This is the default layout/, File.read('output/index.html'))
      assert_match(/This is the page layout/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_other_assigns
    with_site_fixture 'site_with_other_assigns' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(1, Dir[File.join('output', '*')].size)
      assert(File.file?('output/index.html'))
      assert_match(/This page is called "A New Root Page"/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_sublayouts
    with_site_fixture 'site_with_sublayouts' do |site|
      site.compiler.run
      site.compiler.run

      assert_equal(1, Dir[File.join('output', '*')].size)
      assert(File.file?('output/index.html'))

      text = File.read('output/index.html')
      assert(text.include?('<!-- Hi, I\'m Bar! -->'))
      assert(text.include?('<!-- This is the header -->'))
      assert(text.include?('<!-- This is the footer -->'))
    end
  end

end
