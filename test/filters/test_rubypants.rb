require 'test/helper'

class Nanoc3::Filters::RubyPantsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'rubypants' do
      # Get filter
      filter = ::Nanoc3::Filters::RubyPants.new

      # Run filter
      result = filter.run("Wait---what?")
      assert_equal("Wait&#8212;what?", result)
    end
  end

end
