require 'helper'

class FilterERBTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_nothing_raised do
      with_site_fixture 'empty_site' do |site|
        site.load_data

        # Get filter
        filter = ::Nanoc::Filters::ERB.new(site.pages.first.to_proxy, site)

        # Run filter
        result = filter.run('<%= "Hello." %>')
        assert_equal('Hello.', result)
      end
    end
  end

end
