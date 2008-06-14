require 'helper'

class Nanoc::PageRepTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestRouter < Nanoc::Router

    def path_for_page_rep(page_rep)
      path      = page_rep.page.path
      filename  = page_rep.attribute_named(:filename)
      extension = page_rep.attribute_named(:extension)

      '/pages' + path + filename + '.' + extension
    end

  end

  class TestSite

    def config
      @config ||= {
        :output_dir       => 'tmp/output',
        :index_filenames  => [ 'index.html' ]
      }
    end

    def page_defaults
      @page_defaults ||= Nanoc::PageDefaults.new(:foo => 'bar')
    end

    def router
      @router ||= TestRouter.new(self)
    end

  end

  class TestAttributesSite

    def page_defaults
      @page_defaults ||= Nanoc::PageDefaults.new({
        :four => 'four in page defaults',
        :reps => {
          :custom   => { :two   => 'two in page defaults rep'   },
          :default  => { :three => 'three in page defaults rep' }
        }
      })
    end

  end

  def test_initialize
    # TODO implement
  end

  def test_to_proxy
    # TODO implement
  end

  def test_created
    # TODO implement
  end

  def test_modified
    # TODO implement

    # needed for compilation:
    # - page (obviously)
    # - router (for getting disk path)
    # - compiler (for stack)
    # - site config (for output dir)

    # Create page

    # Assert not modified

    # Compile page

    # Assert modified

    # Compile page again

    # Assert not modified

    # Edit and compile page

    # Assert modified
  end

  def test_outdated
    # TODO implement

    # Also check data sources that don't provide mtimes
  end

  def test_disk_and_web_path
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :default }

    # Check
    assert_equal('tmp/output/pages/path/index.html', page_rep.disk_path)
    assert_equal('/pages/path/',                     page_rep.web_path)
  end

  def test_attribute_named_with_custom_rep
    # Should check in
    # 1. page rep
    # 2. page default's page rep
    # 3. hardcoded defaults

    # Create site
    site = TestAttributesSite.new

    # Create page and rep
    page = Nanoc::Page.new(
      "content",
      { :reps => { :custom => { :one => 'one in page rep' } } },
      '/path/'
    )
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :custom }

    # Test finding one
    assert_equal('one in page rep', page_rep.attribute_named(:one))

    # Test finding two
    assert_equal('two in page defaults rep', page_rep.attribute_named(:two))

    # Test finding three
    assert_equal('default', page_rep.attribute_named(:layout))
  end

  def test_attribute_named_with_default_rep
    # Should check in
    # 1. page rep
    # 2. page
    # 3. page defaults' page rep
    # 4. page defaults
    # 5. hardcoded defaults

    # Create site
    site = TestAttributesSite.new

    # Create page and rep
    page = Nanoc::Page.new(
      "content",
      {
        :two => 'two in page',
        :reps => { :default => { :one => 'one in page rep' } }
      },
      '/path/'
    )
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :default }

    # Test finding one
    assert_equal('one in page rep', page_rep.attribute_named(:one))

    # Test finding two
    assert_equal('two in page', page_rep.attribute_named(:two))

    # Test finding three
    assert_equal('three in page defaults rep', page_rep.attribute_named(:three))

    # Test finding four
    assert_equal('four in page defaults', page_rep.attribute_named(:four))

    # Test finding five
    assert_equal('default', page_rep.attribute_named(:layout))
  end

  def test_content
    # TODO implement
  end

  def test_layout
    # TODO implement
  end

  def test_compile
    # TODO implement
    
    # - check modified
    # - check stack
  end

  def test_compile_without_layout
    # TODO implement
  end

  def test_do_filter
    # TODO implement
  end

  def test_do_filter_get_filters_for_stage
    # TODO implement
  end

  def test_do_filter_chained
    # TODO implement
  end

  def test_do_filter_with_unknown_filter
    # TODO implement
  end

  def test_do_layout
    # TODO implement
  end

  def test_do_layout_without_layout
    # TODO implement
  end

  def test_do_layout_with_unknown_filter
    # TODO implement
  end

  def test_write_page
    # TODO implement
  end

  def test_write_page_with_skip_output
    # TODO implement
  end

  def test_do_filter_with_outdated_filters_attribute
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new("content", { :filters => [ 'asdf' ] }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :default }

    # Filter
    assert_raise Nanoc::Errors::NoLongerSupportedError do
      page_rep.instance_eval { filter!(:pre) }
    end
  end

end
