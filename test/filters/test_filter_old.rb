require 'helper'

class Nanoc::Filters::OldTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_raise(SystemExit) do
      with_site_fixture 'empty_site' do |site|
        site.load_data

        # Get filter
        filter = ::Nanoc::Filters::Old.new(site.pages.first.to_proxy, site)

        # Run filter
        result = filter.run("blah")
      end
    end
  end

end
