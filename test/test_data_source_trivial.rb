require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class DataSourceTrivialTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  # Test preparation

  def test_up
    # TODO implement
  end

  def test_down
    # TODO implement
  end

  def test_setup
    # TODO implement
  end

  # Test loading data

  def test_pages
    # TODO implement
  end

  def test_page_defaults
    # TODO implement
  end

  def test_templates
    # TODO implement
  end

  def test_layouts
    # TODO implement
  end

  def test_code
    # TODO implement
  end

  # Test creating data

  def test_create_page
    with_site_fixture 'site_with_trivial_backend' do |site|
      assert_raise(SystemExit)  { site.create_page('test') }
    end
  end

  def test_create_template
    with_site_fixture 'site_with_trivial_backend' do |site|
      assert_raise(SystemExit)  { site.create_page('test') }
    end
  end

  def test_create_layout
    with_site_fixture 'site_with_trivial_backend' do |site|
      assert_raise(SystemExit)  { site.create_page('test') }
    end
  end

  # Miscellaneous

  def test_compile_site
    with_site_fixture 'site_with_trivial_backend' do |site|
      assert_nothing_raised() { site.compile }
      assert(File.file?('output/index.html'))
      assert(File.file?('output/about/index.html'))
      assert_equal(2, Dir["output/*"].size)
      assert_match(/<body>\nHi!\n  <\/body>/, File.read('output/index.html'))
      assert_match(/<body>\nHello there.\n  <\/body>/, File.read('output/about/index.html'))
    end
  end

end
