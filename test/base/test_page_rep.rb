require 'helper'

class Nanoc::PageRepTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestRouter < Nanoc::Router

    def path_for(page_rep)
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

  def test_disk_and_web_path
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site
    page_rep = page.reps.find { |r| r.name == :default }

    # Check
    assert_equal('tmp/output/pages/path/index.html', page_rep.disk_path)
    assert_equal('/pages/path/',                     page_rep.web_path)
  end

  def test_do_filter_with_outdated_filters_attribute
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new("content", { :filters => [ 'asdf' ] }, '/path/')
    page.site = site
    page_rep = page.reps.find { |r| r.name == :default }

    # Filter
    assert_raise Nanoc::Errors::NoLongerSupportedError do
      page_rep.instance_eval { filter!(:pre) }
    end
  end

end
