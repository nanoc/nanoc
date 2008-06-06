require 'helper'

class Nanoc::Filters::DiscountTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'discount' do
      assert_nothing_raised do
        with_temp_site do |site|
          # Get filter
          page_rep  = site.pages[0].reps[0].to_proxy
          page      = site.pages[0].to_proxy
          filter = ::Nanoc::Filters::Discount.new(page_rep, page, site)

          # Run filter
          result = filter.run("> Quote")
          assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
        end
      end
    end
  end

end
