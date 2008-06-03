require 'helper'

class Nanoc::Filters::DiscountTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'discount' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

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
