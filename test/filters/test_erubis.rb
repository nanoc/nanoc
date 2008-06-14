require 'helper'

class Nanoc::Filters::ErubisTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'erubis' do
      assert_nothing_raised do
        with_temp_site do |site|
          # Get filter
          page_rep  = site.pages[0].reps[0].to_proxy
          page      = site.pages[0].to_proxy
          filter = ::Nanoc::Filters::Erubis.new(:page, page_rep, page, site)

          # Run filter
          result = filter.run('<%= "Hello." %>')
          assert_equal('Hello.', result)
        end
      end
    end
  end

end
