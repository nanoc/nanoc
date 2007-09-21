require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class CoreExtStringTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    $quiet = false
  end

  def test_starts_with
    assert('bar'.starts_with?('b'))
    assert('bar'.starts_with?('ba'))
    assert('bar'.starts_with?('bar'))
    assert(!'bar'.starts_with?('barasdf'))
    assert(!'bar'.starts_with?('asdfbar'))
    assert(!'bar'.starts_with?('xyzzy'))
  end

  def test_ends_with
    assert('bar'.ends_with?('r'))
    assert('bar'.ends_with?('ar'))
    assert('bar'.ends_with?('bar'))
    assert(!'bar'.ends_with?('barasdf'))
    assert(!'bar'.ends_with?('asdfbar'))
    assert(!'bar'.ends_with?('xyzzy'))
  end

end
