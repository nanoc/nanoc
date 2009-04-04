require 'test/helper'

class Nanoc::Filters::RubyPantsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'rubypants' do
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
      filter = ::Nanoc::Filters::SmartyPants.new(page_rep)

      # Run filter
      result = filter.run("Wait---what?")
      assert_equal("Wait&#8212;what?", result)
    end
  end

end
