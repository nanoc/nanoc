require 'test/helper'

class Nanoc3::Helpers::XMLSitemapTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::XMLSitemap

  def test_xml_sitemap
    if_have 'builder' do
      # Create items
      @items = [ mock, mock, mock, mock ]

      # Create item 0
      @items[0].expects(:is_hidden).returns(false)
      @items[0].expects(:skip_output).returns(false)
      @items[0].expects(:path).returns('/foo/')
      @items[0].expects(:mtime).returns(nil)
      @items[0].expects(:changefreq).returns(nil)
      @items[0].expects(:priority).returns(nil)

      # Create item 1
      @items[1].expects(:is_hidden).returns(true)

      # Create item 2
      @items[2].expects(:is_hidden).returns(false)
      @items[2].expects(:skip_output).returns(false)
      @items[2].expects(:path).returns('/baz/')
      @items[2].expects(:mtime).times(2).returns(Time.parse('12/07/2004'))
      @items[2].expects(:changefreq).times(2).returns('daily')
      @items[2].expects(:priority).times(2).returns(0.5)

      # Create item 3
      @items[3].expects(:is_hidden).returns(false)
      @items[3].expects(:skip_output).returns(true)

      # Create sitemap item
      @item = mock

      # Create site
      config = mock
      config.expects(:[]).with(:base_url).at_least_once.returns('http://example.com')
      @site = mock
      @site.expects(:config).at_least_once.returns(config)

      # Check
      xml_sitemap
    end
  ensure
    @items = nil
    @item  = nil
    @site  = nil
  end

end
