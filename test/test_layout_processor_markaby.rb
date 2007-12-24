require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class LayoutProcessorMarkabyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_layout_processor
    if_have 'markaby' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

          # Get layout processor
          page  = site.pages.first.to_proxy
          pages = site.pages.map { |p| p.to_proxy }
          layout_processor = ::Nanoc::LayoutProcessor::Markaby::MarkabyLayoutProcessor.new(page, pages, site.config, site)

          # Run layout processor
          result = layout_processor.run('h1 { page.title }')
          assert_equal("<h1>My New Homepage</h1>", result)
        end
      end
    end
  end

end
