require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class LayoutProcessorHamlTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_layout_processor
    if_have 'haml' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

          # Get layout processor
          page  = site.pages.first.to_proxy
          pages = site.pages.map { |p| p.to_proxy }
          layout_processor = ::Nanoc::LayoutProcessor::Haml::HamlLayoutProcessor.new(page, pages, site.config, site)

          # Run filter
          result = layout_processor.run('%html')
          assert_equal("<html>\n</html>\n", result)

          # Run filter
          result = layout_processor.run('%h1= page.title')
          assert_equal("<h1>My New Homepage</h1>\n", result)

          # Run filter
          result = layout_processor.run('%h1= @page.title')
          assert_equal("<h1>My New Homepage</h1>\n", result)
        end
      end
    end
  end

end
