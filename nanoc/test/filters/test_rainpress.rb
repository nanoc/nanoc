# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::RainpressTest < Nanoc::TestCase
  def test_filter
    # Create filter
    filter = ::Nanoc::Filters::Rainpress.new

    # Run filter
    result = filter.setup_and_run('body { color: black; }')

    assert_equal('body{color:#000}', result)
  end

  def test_filter_with_options
    # Create filter
    filter = ::Nanoc::Filters::Rainpress.new

    # Run filter
    result = filter.setup_and_run('body { color: #aabbcc; }', colors: false)

    assert_equal('body{color:#aabbcc}', result)
  end
end
