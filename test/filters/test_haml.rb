require 'helper'

class Nanoc::Filters::HamlTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'haml' do
      assert_nothing_raised do
        with_temp_site do |site|
          # Get filter
          filter = ::Nanoc::Filters::Haml.new(site.pages.first.to_proxy, site)

          # Run filter (no assigns)
          result = filter.run('%html')
          assert_match(/<html>.*<\/html>/, result)

          # Run filter (assigns without @)
          result = filter.run('%p= page.title')
          assert_equal("<p>A New Root Page</p>\n", result)

          # Run filter (assigns with @)
          result = filter.run('%p= @page.title')
          assert_equal("<p>A New Root Page</p>\n", result)
        end
      end
    end
  end

end
