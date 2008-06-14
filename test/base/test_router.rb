require 'helper'

class Nanoc::RouterTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestSite

    def config
      @config ||= {
        :output_dir       => 'tmp/out',
        :index_filenames  => [ 'home.htm' ]
      }
    end

    def page_defaults
      @page_defaults ||= Nanoc::PageDefaults.new({})
    end

  end

  class TestRouter < Nanoc::Router

    def path_for_page_rep(page_rep)
      path      = page_rep.page.path
      filename  = page_rep.attribute_named(:filename)
      extension = page_rep.attribute_named(:extension)

      path + filename + '.' + extension
    end

  end

  def test_path_for_page_rep
    # Create router
    router = Nanoc::Router.new(nil)

    # Make sure an error is raised
    assert_raise(NotImplementedError) do
      router.path_for_page_rep(nil)
    end
  end

  def test_disk_path_for
    # Create stuff we need
    site    = TestSite.new
    router  = TestRouter.new(site)

    # Create test pages
    pages = {
      :with_cp_without_index => Nanoc::Page.new(
        'page with cp',
        { :custom_path => '/with/cp/moo.html' },
        '/with/cp/without/index/'
      ),
      :with_cp_with_index => Nanoc::Page.new(
        'page without cp',
        { :custom_path => '/with/cp/with/index/home.htm'},
        '/with/cp/with/index/'
      ),
      :without_cp_without_index => Nanoc::Page.new(
        'page without cp, without index',
        { :filename => 'foo' },
        '/without/cp/without/index/'
      ),
      :without_cp_with_index => Nanoc::Page.new(
        'page without cp, with index',
        { :filename => 'home', :extension => 'htm' },
        '/without/cp/with/index/'
      )
    }
    pages.values.each do |page|
      page.site = site
      page.build_reps
    end

    # Check
    assert_nothing_raised do
      assert_equal(
        'tmp/out/with/cp/moo.html',
        router.disk_path_for(pages[:with_cp_without_index].reps.find { |r| r.name == :default })
      )
      assert_equal(
        'tmp/out/with/cp/with/index/home.htm',
        router.disk_path_for(pages[:with_cp_with_index].reps.find { |r| r.name == :default })
      )
      assert_equal(
        'tmp/out/without/cp/without/index/foo.html',
        router.disk_path_for(pages[:without_cp_without_index].reps.find { |r| r.name == :default })
      )
      assert_equal(
        'tmp/out/without/cp/with/index/home.htm',
        router.disk_path_for(pages[:without_cp_with_index].reps.find { |r| r.name == :default })
      )
    end
  end

  def test_web_path_for
    # Create stuff we need
    site    = TestSite.new
    router  = TestRouter.new(site)

    # Create test pages
    pages = {
      :with_cp_without_index => Nanoc::Page.new(
        'page with cp',
        { :custom_path => '/with/cp/moo.html' },
        '/with/cp/without/index/'
      ),
      :with_cp_with_index => Nanoc::Page.new(
        'page without cp',
        { :custom_path => '/with/cp/with/index/home.htm'},
        '/with/cp/with/index/'
      ),
      :without_cp_without_index => Nanoc::Page.new(
        'page without cp, without index',
        { :filename => 'foo' },
        '/without/cp/without/index/'
      ),
      :without_cp_with_index => Nanoc::Page.new(
        'page without cp, with index',
        { :filename => 'home', :extension => 'htm' },
        '/without/cp/with/index/'
      )
    }
    pages.values.each do |page|
      page.site = site
      page.build_reps
    end

    # Check
    assert_nothing_raised do
      assert_equal(
        '/with/cp/moo.html',
        router.web_path_for(pages[:with_cp_without_index].reps.find { |r| r.name == :default })
      )
      assert_equal(
        '/with/cp/with/index/',
        router.web_path_for(pages[:with_cp_with_index].reps.find { |r| r.name == :default })
      )
      assert_equal(
        '/without/cp/without/index/foo.html',
        router.web_path_for(pages[:without_cp_without_index].reps.find { |r| r.name == :default })
      )
      assert_equal(
        '/without/cp/with/index/',
        router.web_path_for(pages[:without_cp_with_index].reps.find { |r| r.name == :default })
      )
    end
  end

end
