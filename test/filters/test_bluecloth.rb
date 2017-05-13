# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::BlueClothTest < Nanoc::TestCase
  def test_filter
    if_have 'bluecloth' do
      # Create filter
      filter = ::Nanoc::Filters::BlueCloth.new

      # Run filter
      result = filter.setup_and_run('> Quote')
      assert_match %r{<blockquote>\s*<p>Quote</p>\s*</blockquote>}, result
    end
  end
end
