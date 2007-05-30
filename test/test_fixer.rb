require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class FixerTest < Test::Unit::TestCase
  def setup
    $quiet = true
  end

  def teardown
    $quiet = false
  end

  def test_something
  end
end
