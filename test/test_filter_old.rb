require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterOldTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_raise(SystemExit) do
      with_site_fixture 'empty_site' do |site|
        site.load_data

        # Get filter
        filter = ::Nanoc::Filters::OldFilter.new(site.pages.first.to_proxy, site)

        # Run filter
        result = filter.run("blah")
      end
    end
  end

end
