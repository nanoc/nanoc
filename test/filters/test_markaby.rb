require 'helper'

class Nanoc::Filters::MarkabyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'markaby' do
      assert_nothing_raised do
        with_temp_site do |site|
          # Get filter
          page_rep  = site.pages[0].reps[0].to_proxy
          page      = site.pages[0].to_proxy
          filter = ::Nanoc::Filters::Markaby.new(:page, page_rep, page, site)

          # Run filter
          result = filter.run("html do\nend")
          assert_equal("<html></html>", result)
        end
      end
    end
  end

end
