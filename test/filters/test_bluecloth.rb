# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::BlueClothTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'bluecloth' do
      # Create filter
      filter = ::Nanoc3::Filters::BlueCloth.new

      # Run filter
      result = filter.run("> Quote")
      assert_match %r{<blockquote>\s*<p>Quote</p>\s*</blockquote>}, result
    end
  end

end
