require 'test/helper'

class Nanoc::Filters::RDiscountTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'rdiscount' do
      # Create site
      site = mock

      # Create page
      page = mock
      page.expects(:site).returns(site)

      # Create page rep
      page_rep = mock
      page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
      page_rep.expects(:page).returns(page)

      # Get filter
      filter = ::Nanoc::Filters::RDiscount.new(page_rep)

      # Run filter
      result = filter.run("> Quote")
      assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
    end
  end

end
