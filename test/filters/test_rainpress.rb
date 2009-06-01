# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::RainpressTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'rainpress' do
      # Create filter
      filter = ::Nanoc3::Filters::Rainpress.new

      # Run filter
      result = filter.run("body { color: black; }")
      assert_equal("body{color:#000}", result)
    end
  end

end
