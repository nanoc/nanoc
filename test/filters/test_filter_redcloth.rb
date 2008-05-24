require 'helper'

class FilterRedClothTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'redcloth' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

          # Get filter
          filter = ::Nanoc::Filters::RedCloth.new(site.pages.first.to_proxy, site)

          # Run filter
          result = filter.run("h1. Foo")
          assert_equal("<h1>Foo</h1>", result)
        end
      end
    end
  end

end
