require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class FiltersTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    $quiet = false
  end

  def test_string_erb
  end

end
