require 'test/helper'

class Nanoc::Filters::HamlTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'haml' do
      # Create site
      site = mock

      # Create page
      page = mock
      page_proxy = Nanoc::Proxy.new(page)
      page.stubs(:site).returns(site)
      page.stubs(:to_proxy).returns(page_proxy)
      page.stubs(:attribute_named).with(:title).times(2).returns('Home', 'Home')
      page.stubs(:path).returns('/moo/')

      # Create page rep
      page_rep = mock
      page_rep_proxy = Nanoc::Proxy.new(page_rep)
      page_rep.stubs(:is_a?).with(Nanoc::PageRep).returns(true)
      page_rep.stubs(:page).returns(page)
      page_rep.stubs(:to_proxy).returns(page_rep_proxy)
      page_rep.stubs(:attribute_named).times(3).returns({}, {}, {})
      page_rep.stubs(:name).returns(:foobar)

      # Mock site
      site.stubs(:pages).returns([])
      site.stubs(:assets).returns([])
      site.stubs(:layouts).returns([])
      site.stubs(:config).returns({})

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
