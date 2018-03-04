# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::BlueClothTest < Nanoc::TestCase
  def test_filter
    skip_unless_have 'bluecloth'

    # Create filter
    filter = ::Nanoc::Filters::BlueCloth.new

    # Run filter
    result = filter.setup_and_run('> Quote')
    assert_match %r{<blockquote>\s*<p>Quote</p>\s*</blockquote>}, result
  end
end
