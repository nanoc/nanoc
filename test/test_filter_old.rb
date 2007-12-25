require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterMarukuTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_raise(SystemExit) do
      with_site_fixture 'empty_site' do |site|
        site.load_data

        # Get filter
        page  = site.pages.first.to_proxy
        pages = site.pages.map { |p| p.to_proxy }
        filter = ::Nanoc::Filter::Old::OldFilter.new(page, pages, site.config, site)

        # Run filter
        result = filter.run("blah")
      end
    end
  end

end
