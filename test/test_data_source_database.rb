require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class DatabaseDataSourceTest < Test::Unit::TestCase

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
  end

  def test_create_template
  end

  def test_create_layout
  end

end
