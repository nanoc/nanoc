require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class FilterMarkdownTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    test_require 'bluecloth'

    assert_nothing_raised do
      with_site_fixture 'empty_site' do
        # Get site
        site = Nanoc::Site.from_cwd
        site.load_data

        # Get filter
        filter = ::Nanoc::Filter::Markdown::MarkdownFilter.new(site.pages.first, site.pages, site.config, site)

        # Run filter
        result = filter.run("> Quote")
        assert_equal("<blockquote>\n    <p>Quote</p>\n</blockquote>", result)
      end
    end
  end

end
