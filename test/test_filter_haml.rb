require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterHamlTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    test_require 'haml'

    assert_nothing_raised do
      with_site_fixture 'empty_site' do
        # Get site
        site = Nanoc::Site.from_cwd
        site.load_data

        # Get filter
        filter = ::Nanoc::Filter::Haml::HamlFilter.new(site.pages.first, site.pages, site.config, site)

        # Run filter
        result = filter.run('%html')
        assert_equal("<html>\n</html>\n", result)
      end
    end
  end

end
