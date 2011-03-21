# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::RubyPantsTest < Nanoc3::TestCase

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
