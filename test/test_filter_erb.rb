require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterERBTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    # Get filter
    erb_filter = Nanoc::PluginManager.filter_named(:erb)
    assert(!erb_filter.nil?)

    # TODO implement
  end

end
