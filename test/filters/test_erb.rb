require 'test/helper'

class Nanoc::Filters::ERBTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    # Create site
    site = mock

    # Create page
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:site).returns(site)
    page.expects(:to_proxy).returns(page_proxy)
    page.expects(:path).returns('/moo/')

    # Create page rep
    page_rep = mock
    page_rep_proxy = Nanoc::Proxy.new(page_rep)
    page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    page_rep.expects(:page).returns(page)
    page_rep.expects(:to_proxy).returns(page_rep_proxy)
    page_rep.expects(:name).returns(:foobar)

    # Mock site
    site.expects(:pages).returns([])
    site.expects(:assets).returns([])
    site.expects(:layouts).returns([])
    site.expects(:config).returns({})

    # Get filter
    filter = ::Nanoc::Filters::ERB.new(page_rep)

    # Run filter
    result = filter.run('<%= "Hello." %>')
    assert_equal('Hello.', result)
  end

end
