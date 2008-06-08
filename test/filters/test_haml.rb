require 'helper'

class Nanoc::Filters::HamlTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'haml' do
      assert_nothing_raised do
        with_temp_site do |site|
          # Get filter
          page_rep  = site.pages[0].reps[0].to_proxy
          page      = site.pages[0].to_proxy
          filter = ::Nanoc::Filters::Haml.new(page_rep, page, site)

          # Run filter (no assigns)
          result = filter.run('%html')
          assert_match(/<html>.*<\/html>/, result)

          # Run filter (assigns without @)
          result = filter.run('%p= page.title')
          assert_equal("<p>Home</p>\n", result)

          # Run filter (assigns with @)
          result = filter.run('%p= @page.title')
          assert_equal("<p>Home</p>\n", result)
        end
      end
    end
  end

end
