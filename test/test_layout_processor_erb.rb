require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class LayoutProcessorERBTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_layout_processor
    assert_nothing_raised do
      with_site_fixture 'empty_site' do |site|
        site.load_data

        # Get layout processor
        layout_processor = ::Nanoc::Filters::ERB.new(site.pages.first.to_proxy, site)

        # Run layout processor
        result = layout_processor.run('<%= @page.title %>')
        assert_equal('My New Homepage', result)
      end
    end
  end

end
