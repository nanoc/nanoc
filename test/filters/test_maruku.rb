require 'helper'

class Nanoc::Filters::MarukuTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'maruku' do
      assert_nothing_raised do
        with_temp_site do |site|
          # Get filter
          page_rep  = site.pages[0].reps[0].to_proxy
          page      = site.pages[0].to_proxy
          filter = ::Nanoc::Filters::Maruku.new(:page, page_rep, page, site)

          # Run filter
          result = filter.run("This is _so_ *cool*!")
          assert_equal("<p>This is <em>so</em> <em>cool</em>!</p>", result)
        end
      end
    end
  end

end
