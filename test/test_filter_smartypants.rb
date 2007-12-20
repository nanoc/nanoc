require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterSmartyPantsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    test_require 'rubypants'

    assert_nothing_raised do
      with_site_fixture 'empty_site' do
        # Get site
        site = Nanoc::Site.from_cwd
        site.load_data

        # Get filter
        filter = ::Nanoc::Filter::SmartyPants::SmartyPantsFilter.new(site.pages.first, site.pages, site.config, site)

        # Run filter
        result = filter.run("Wait---what?")
        assert_equal("Wait&#8212;what?", result)
      end
    end
  end

end
