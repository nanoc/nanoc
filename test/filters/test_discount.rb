require 'helper'

class Nanoc::Filters::DiscountTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'discount' do
      assert_nothing_raised do
        with_temp_site do |site|
          # Get filter
          filter = ::Nanoc::Filters::Discount.new(site.pages.first.to_proxy, site)

          # Run filter
          result = filter.run("> Quote")
          assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
        end
      end
    end
  end

end
