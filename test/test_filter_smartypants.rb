require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterSmartyPantsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'rubypants' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

          # Get filter
          page  = site.pages.first.to_proxy
          pages = site.pages.map { |p| p.to_proxy }
          filter = ::Nanoc::Filter::SmartyPants::SmartyPantsFilter.new(page, pages, site.config, site)

          # Run filter
          result = filter.run("Wait---what?")
          assert_equal("Wait&#8212;what?", result)
        end
      end
    end
  end

end
