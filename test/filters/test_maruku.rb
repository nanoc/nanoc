require 'test/helper'

class Nanoc::Filters::MarukuTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'maruku' do
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
      filter = ::Nanoc::Filters::Maruku.new(page_rep)

      # Run filter
      result = filter.run("This is _so_ *cool*!")
      assert_equal("<p>This is <em>so</em> <em>cool</em>!</p>", result)
    end
  end

end
