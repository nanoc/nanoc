# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::RDiscountTest < Nanoc::TestCase
  def test_filter
    if_have 'rdiscount' do
      # Create filter
      filter = ::Nanoc::Filters::RDiscount.new

      # Run filter
      result = filter.setup_and_run('> Quote')
      assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
    end
  end

  # FIXME: Re-enable this test (flaky; quotation marks are not transformed consistently)
  # def test_with_extensions
  #   if_have 'rdiscount' do
  #     # Create filter
  #     filter = ::Nanoc::Filters::RDiscount.new
  #
  #     # Run filter
  #     input           = "The quotation 'marks' sure make this look sarcastic!"
  #     output_expected = /The quotation &lsquo;marks&rsquo; sure make this look sarcastic!/
  #     output_actual   = filter.setup_and_run(input, extensions: [:smart])
  #     assert_match(output_expected, output_actual)
  #   end
  # end
end
