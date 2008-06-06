require 'helper'

class Nanoc::Filters::OldTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_raise(Nanoc::Error) do
      with_temp_site do |site|
        # Get filter
        page_rep  = site.pages[0].reps[0].to_proxy
        page      = site.pages[0].to_proxy
        filter = ::Nanoc::Filters::Old.new(page_rep, page, site)

        # Run filter
        result = filter.run("blah")
      end
    end
  end

end
