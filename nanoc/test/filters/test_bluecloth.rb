# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::BlueClothTest < Nanoc::TestCase
  def test_filter
    skip_unless_have 'bluecloth'

    # Skip if nonfunctional
    begin
      ::BlueCloth.new('# hi').to_html
    rescue ArgumentError => e
      skip 'BlueCloth is broken on this platform' if e.message.include?('wrong number of arguments')
    end

    # Create filter
    filter = ::Nanoc::Filters::BlueCloth.new

    # Run filter
    result = filter.setup_and_run('> Quote')

    assert_match %r{<blockquote>\s*<p>Quote</p>\s*</blockquote>}, result
  end
end
