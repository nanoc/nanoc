require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class TrivialDataSourceTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure f if File.exist?(f)}
    $quiet = false
  end

  # Test preparation

  def test_up
  end

  def test_down
  end

  def test_setup
  end

  # Test loading data

  def test_pages
  end

  def test_page_defaults
  end

  def test_templates
  end

  def test_layouts
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
      assert_match(/<body>Hi!<\/body>/, File.read('output/index.html'))
      assert_match(/<body>Hello there.<\/body>/, File.read('output/about/index.html'))
    end
  end

end
