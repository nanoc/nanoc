require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class DatabaseBackendTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    $quiet = false
  end

  def test_foo
  end

end
