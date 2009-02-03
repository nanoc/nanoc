require 'test/helper'

class Nanoc::Filters::RDiscountTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'rdiscount' do
      assert_nothing_raised do
        # Create filter
        filter = ::Nanoc::Filters::RDiscount.new

        # Run filter
        result = filter.run("> Quote")
        assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
      end
    end
  end

end
