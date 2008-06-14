require 'helper'

class Nanoc::Routers::DefaultTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestSite

    def page_defaults
      @page_defaults ||= Nanoc::PageDefaults.new(:foo => 'bar')
    end

  end

  def test_path_for_page_rep
    # Create default router
    router = Nanoc::Routers::Default.new(nil)

    # Create site
    site = TestSite.new

    # Get page
    page = Nanoc::Page.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/foo/'
    )
    page.site = site
    page.build_reps

    # Check
    assert_equal('/foo/home.htm', router.path_for_page_rep(page.reps.find { |r| r.name == :default }))
  end

end
