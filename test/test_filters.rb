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
    assert_equal('moo', '<%= "moo" %>'.erb)
    assert_equal('bar', '<%= @foo %>'.erb(:assigns => { :foo => 'bar' }))
  end

end
