require 'helper'

class Nanoc::PageRepTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_do_filter_with_outdated_filters_attribute
    # Create page
    page = Nanoc::Page.new("content", { :filters => [ 'asdf' ] }, '/path/')
    page_rep = page.reps[:default]

    # Filter
    assert_raise Nanoc::Errors::NoLongerSupportedError do
      page_rep.instance_eval { filter!(:pre) }
    end
  end

end
