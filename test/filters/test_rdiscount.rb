require 'test/helper'

class Nanoc3::Filters::RDiscountTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

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
