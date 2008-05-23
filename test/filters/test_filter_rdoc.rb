require 'test/unit'

require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class FilterRDocTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_nothing_raised do
      with_site_fixture 'empty_site' do |site|
        site.load_data

        # Get filter
        filter = ::Nanoc::Filters::RDoc.new(site.pages.first.to_proxy, site)

        # Run filter
        result = filter.run("= Foo")
        assert_equal("<h1>Foo</h1>\n", result)
      end
    end
  end

end
