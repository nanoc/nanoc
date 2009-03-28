require 'test/helper'

class Nanoc3::Helpers::XMLSitemapTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc3::Helpers::XMLSitemap

  def test_xml_sitemap
    if_have 'builder' do
      # Create pages
      @pages = [ mock, mock, mock, mock ]

      # Create page 0
      @pages[0].expects(:is_hidden).returns(false)
      @pages[0].expects(:skip_output).returns(false)
      @pages[0].expects(:path).returns('/foo/')
      @pages[0].expects(:mtime).returns(nil)
      @pages[0].expects(:changefreq).returns(nil)
      @pages[0].expects(:priority).returns(nil)

      # Create page 1
      @pages[1].expects(:is_hidden).returns(true)

      # Create page 2
      @pages[2].expects(:is_hidden).returns(false)
      @pages[2].expects(:skip_output).returns(false)
      @pages[2].expects(:path).returns('/baz/')
      @pages[2].expects(:mtime).times(2).returns(Time.parse('12/07/2004'))
      @pages[2].expects(:changefreq).times(2).returns('daily')
      @pages[2].expects(:priority).times(2).returns(0.5)

      # Create page 3
      @pages[3].expects(:is_hidden).returns(false)
      @pages[3].expects(:skip_output).returns(true)

      # Create sitemap page
      @page = mock

      # Create site
      config = mock
      config.expects(:[]).with(:base_url).at_least_once.returns('http://example.com')
      @site = mock
      @site.expects(:config).at_least_once.returns(config)

      # Check
      xml_sitemap
    end
  ensure
    @pages = nil
    @page  = nil
    @site  = nil
  end

end
