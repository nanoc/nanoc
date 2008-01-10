require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterHamlTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'haml' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

          # Get filter
          filter = ::Nanoc::Filters::HamlFilter.new(site.pages.first.to_proxy, site)

          # Run filter
          result = filter.run('%html')
          assert_equal("<html>\n</html>\n", result)
        end
      end
    end
  end

end
