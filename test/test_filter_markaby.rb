require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterMarkabyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    test_require 'markaby'

    assert_nothing_raised do
      with_site_fixture 'empty_site' do
        # Get site
        site = ::Nanoc::Site.from_cwd
        site.load_data

        # Get filter
        page  = site.pages.first.to_proxy
        pages = site.pages.map { |p| p.to_proxy }
        filter = ::Nanoc::Filter::Markaby::MarkabyFilter.new(page, pages, site.config, site)

        # Run filter
        result = filter.run("html do\nend")
        assert_equal("<html></html>", result)
      end
    end
  end

end
