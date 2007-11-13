require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class SiteTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    $quiet = false
  end

  def test_create_page
  end

  def test_create_page_with_existing_name
  end

  def test_create_template
  end

  def test_create_template_with_existing_name
  end

  def test_create_layout
  end

  def test_create_layout_with_existing_name
  end

end
