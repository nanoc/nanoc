require 'helper'

class Nanoc::Filters::RDocTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_nothing_raised do
      with_temp_site do |site|
        # Get filter
        page_rep  = site.pages[0].reps[0].to_proxy
        page      = site.pages[0].to_proxy
        filter = ::Nanoc::Filters::RDoc.new(:page, page_rep, page, site)

        # Run filter
        result = filter.run("= Foo")
        assert_equal("<h1>Foo</h1>\n", result)
      end
    end
  end

end
