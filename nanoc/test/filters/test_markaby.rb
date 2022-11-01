# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::MarkabyTest < Nanoc::TestCase
  def test_filter
    skip 'known broken on Ruby 3.x' if RUBY_VERSION.start_with?('3')

    # Create filter
    filter = ::Nanoc::Filters::Markaby.new

    # Run filter
    result = filter.setup_and_run("html do\nend")

    assert_equal('<html></html>', result)
  end
end
