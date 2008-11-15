require 'helper'

class Nanoc::Filters::HamlTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'haml' do
      assert_nothing_raised do
        # Create site
        site = mock

        # Create page
        page = mock
        page_proxy = Nanoc::Proxy.new(page)
        page.expects(:site).returns(site)
        page.expects(:to_proxy).returns(page_proxy)
        page.expects(:attribute_named).with(:title).times(2).returns('Home', 'Home')

        # Create page rep
        page_rep = mock
        page_rep_proxy = Nanoc::Proxy.new(page_rep)
        page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
        page_rep.expects(:page).returns(page)
        page_rep.expects(:to_proxy).returns(page_rep_proxy)
        page_rep.expects(:attribute_named).times(3).returns({}, {}, {})

        # Mock site
        site.expects(:pages).returns([])
        site.expects(:assets).returns([])
        site.expects(:layouts).returns([])
        site.expects(:config).returns({})

        # Get filter
        filter = ::Nanoc::Filters::Haml.new(page_rep)

        # Run filter (no assigns)
        result = filter.run('%html')
        assert_match(/<html>.*<\/html>/, result)

        # Run filter (assigns without @)
        result = filter.run('%p= page.title')
        assert_equal("<p>Home</p>\n", result)

        # Run filter (assigns with @)
        result = filter.run('%p= @page.title')
        assert_equal("<p>Home</p>\n", result)
      end
    end
  end

end
