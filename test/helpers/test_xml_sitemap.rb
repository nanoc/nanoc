# encoding: utf-8

require 'test/helper'

class Nanoc3::Helpers::XMLSitemapTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::XMLSitemap

  def test_xml_sitemap
    if_have 'builder' do
      # Create items
      @items = [ mock, mock, mock, mock ]

      # Create item 0
      @items[0].expects(:[]).with(:is_hidden).returns(false)
      @items[0].expects(:[]).with(:skip_output).returns(false)
      @items[0].expects(:mtime).times(2).returns(nil)
      @items[0].expects(:[]).times(2).with(:changefreq).returns(nil)
      @items[0].expects(:[]).times(2).with(:priority).returns(nil)
      item_reps = [ mock, mock ]
      item_reps[0].expects(:path).returns('/kkk/')
      item_reps[1].expects(:path).returns('/lll/')
      @items[0].expects(:reps).returns(item_reps)

      # Create item 1
      @items[1].expects(:[]).with(:is_hidden).returns(true)

      # Create item 2
      @items[2].expects(:[]).with(:is_hidden).returns(false)
      @items[2].expects(:[]).with(:skip_output).returns(false)
      @items[2].expects(:mtime).times(4).returns(Time.parse('12/07/2004'))
      @items[2].expects(:[]).with(:changefreq).times(4).returns('daily')
      @items[2].expects(:[]).with(:priority).times(4).returns(0.5)
      item_reps = [ mock, mock ]
      item_reps[0].expects(:path).returns('/aaa/')
      item_reps[1].expects(:path).returns('/bbb/')
      @items[2].expects(:reps).returns(item_reps)

      # Create item 3
      @items[3].expects(:[]).with(:is_hidden).returns(false)
      @items[3].expects(:[]).with(:skip_output).returns(true)

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
