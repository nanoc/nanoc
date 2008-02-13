require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterMarkabyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'markaby' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

          # Get filter
          filter = ::Nanoc::Filters::Markaby.new(site.pages.first.to_proxy, site)

          # Run filter
          result = filter.run("html do\nend")
          assert_equal("<html></html>", result)
        end
      end
    end
  end

end
