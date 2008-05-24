require 'helper'

class FilterMarukuTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'maruku' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

          # Get filter
          filter = ::Nanoc::Filters::Maruku.new(site.pages.first.to_proxy, site)

          # Run filter
          result = filter.run("This is _so_ *cool*!")
          assert_equal("<p>This is <em>so</em> <em>cool</em>!</p>", result)
        end
      end
    end
  end

end
