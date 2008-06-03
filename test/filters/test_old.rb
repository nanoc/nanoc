require 'helper'

class Nanoc::Filters::OldTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_raise(Nanoc::Error) do
      with_temp_site do |site|
        # Get filter
        filter = ::Nanoc::Filters::Old.new(site.pages.first.to_proxy, site)

        # Run filter
        result = filter.run("blah")
      end
    end
  end

end
