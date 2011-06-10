# encoding: utf-8

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
