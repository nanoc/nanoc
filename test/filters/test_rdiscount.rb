# encoding: utf-8

class Nanoc::Filters::RDiscountTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'rdiscount' do
      # Create filter
      filter = ::Nanoc::Filters::RDiscount.new

      # Run filter
      result = filter.run("> Quote")
      assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
    end
  end

  def test_with_extensions
    if_have 'rdiscount' do
      # Create filter
      filter = ::Nanoc::Filters::RDiscount.new

      # Run filter
      input           = "The quotation 'marks' sure make this look sarcastic!"
      output_expected = /The quotation &lsquo;marks&rsquo; sure make this look sarcastic!/
      output_actual   = filter.run(input, :extensions => [ :smart ])
      assert_match(output_expected, output_actual)
    end
  end

end
