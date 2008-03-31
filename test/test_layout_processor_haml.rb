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
          layout_processor = ::Nanoc::Filters::Haml.new(site.pages.first.to_proxy, site)

          # Run layout processor (no assigns)
          result = layout_processor.run('%html')
          assert_equal("<html>\n</html>\n", result)

          # Run layout processor (assigns without @)
          result = layout_processor.run('%p= page.title')
          assert_equal("<p>My New Homepage</p>\n", result)

          # Run layout processor (assigns with @)
          result = layout_processor.run('%p= @page.title')
          assert_equal("<p>My New Homepage</p>\n", result)
        end
      end
    end
  end

end
