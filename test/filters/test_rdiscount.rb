# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::RDiscountTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'rdiscount' do
      # Create filter
      filter = ::Nanoc3::Filters::RDiscount.new

      # Run filter
      result = filter.run("> Quote")
      assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
    end
  end

end
