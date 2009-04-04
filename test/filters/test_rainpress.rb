require 'test/helper'

class Nanoc::Filters::RainpressTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'rainpress' do
      # Create site
      site = mock

      # Create page
      page = mock
      page.expects(:site).returns(site)

      # Create page rep
      page_rep = mock
      page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
      page_rep.expects(:page).returns(page)

      # Create filter
      filter = ::Nanoc::Filters::Rainpress.new(page_rep)

      # Run filter
      result = filter.run("body { color: black; }")
      assert_equal("body{color:#000}", result)
    end
  end

end
