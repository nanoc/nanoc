# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::RainpressTest < Nanoc3::TestCase

  def test_filter
    if_have 'rainpress' do
      # Create filter
      filter = ::Nanoc3::Filters::Rainpress.new

      # Run filter
      result = filter.run("body { color: black; }")
      assert_equal("body{color:#000}", result)
    end
  end

  def test_filter_with_options
    if_have 'rainpress' do
      # Create filter
      filter = ::Nanoc3::Filters::Rainpress.new

      # Run filter
      result = filter.run("body { color: #aabbcc; }", :colors => false)
      assert_equal("body{color:#aabbcc}", result)
    end
  end

end
