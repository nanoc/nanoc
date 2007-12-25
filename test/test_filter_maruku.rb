require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterMarukuTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'redcloth' do
      assert_nothing_raised do
        with_site_fixture 'empty_site' do |site|
          site.load_data

          # Get filter
          page  = site.pages.first.to_proxy
          pages = site.pages.map { |p| p.to_proxy }
          filter = ::Nanoc::Filter::Maruku::MarukuFilter.new(page, pages, site.config, site)

          # Run filter
          result = filter.run("This is _so_ *cool*!")
          assert_equal("<p>This is <em>so</em> <em>cool</em>!</p>", result)
        end
      end
    end
  end

end
