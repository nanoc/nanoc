require 'test/helper'

class Nanoc::Filters::BlueClothTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'bluecloth' do
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
      filter = ::Nanoc::Filters::BlueCloth.new(page_rep)

      # Run filter
      result = filter.run("> Quote")
      assert_equal("<blockquote>\n    <p>Quote</p>\n</blockquote>", result)
    end
  end

end
