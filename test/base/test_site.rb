require 'helper'

class SiteTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestDataSource < Nanoc::DataSource

    identifier :test_data_source

  end

  class TestOldschoolDataSource < Nanoc::DataSource

    identifier :test_oldschool_data_source

    def pages
      [
        { :uncompiled_content => 'Hi!',          :path => '/'       },
        { :uncompiled_content => 'Hello there.', :path => '/about/' }
      ]
    end

    def page_defaults
      { :layout => 'quux' }
    end

    def layouts
      [
        {
          :path       => '/quux/',
          :content    => "<html>\n" +
                         "  <head>\n" +
                         "    <title><%= @page.title %></title>\n" +
                         "  </head>\n" +
                         "  <body>\n" +
                         "<%= @page.content %>\n" +
                         "  </body>\n" +
                         "</html>",
          :meta       => { :filter => 'erb' }
        }
      ]
    end

    def templates
      [
        {
          :name     => 'default',
          :content  => 'Hi, I am a new page. Please edit me!',
          :meta     => { :title => 'A New Page' }
        }
      ]
    end

    def code
      "def foo ; 'bar' ; end"
    end

  end

  class TestNewschoolDataSource < Nanoc::DataSource

    identifier :test_newschool_data_source

    def pages
      [
        Nanoc::Page.new("Hi!",          {}, '/'),
        Nanoc::Page.new("Hello there.", {}, '/about/')
      ]
    end

    def page_defaults
      Nanoc::PageDefaults.new({ :foo => 'bar' })
    end

    def layouts
      [
        Nanoc::Layout.new(
          'HEADER <%= @page.content %> FOOTER',
          { :filter => 'erb' },
          '/quux/'
        )
      ]
    end

    def templates
      [
        Nanoc::Template.new('default', 'Content Here', { :foo => 'bar' })
      ]
    end

    def code
      Nanoc::Code.new("def something_random ; 'something random, yah' ; end")
    end

  end

  class TestRouter < Nanoc::Router

    identifier :test_router

  end

  def test_initialize
    # Test everything okay
    assert_nothing_raised do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'filesystem',
        :router       => 'default'
      )
    end

    # Test unknown data source
    assert_raise(Nanoc::Errors::UnknownDataSourceError) do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'kasdflksafjlksdjaklfkjdsjakf',
        :router       => 'default'
      )
    end

    # Test unknown router
    assert_raise(Nanoc::Errors::UnknownRouterError) do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'filesystem',
        :router       => 'kasdflksafjlksdjaklfkjdsjakf'
      )
    end
  end

  def test_load_data
    # Create site with oldschool data source
    site = nil
    assert_nothing_raised do
      site = Nanoc::Site.new(:data_source => 'test_oldschool_data_source')
      site.load_data
    end

    # Check classes
    assert(site.pages.all? { |p| p.is_a?(Nanoc::Page) })
    assert(site.page_defaults.is_a?(Nanoc::PageDefaults))
    assert(site.layouts.all? { |l| l.is_a?(Nanoc::Layout) })
    assert(site.templates.all? { |t| t.is_a?(Nanoc::Template) })
    assert(site.code.is_a?(Nanoc::Code))

    # Check whether site is set
    assert(site.pages.all? { |p| p.site == site })
    assert(site.page_defaults.site == site)
    assert(site.layouts.all? { |l| l.site == site })
    assert(site.templates.all? { |t| t.site == site })
    assert(site.code.site == site)

    # Create site with newschool data source
    site = nil
    assert_nothing_raised do
      site = Nanoc::Site.new(:data_source => 'test_newschool_data_source')
      site.load_data
    end

    # Check classes
    assert(site.pages.all? { |p| p.is_a?(Nanoc::Page) })
    assert(site.page_defaults.is_a?(Nanoc::PageDefaults))
    assert(site.layouts.all? { |l| l.is_a?(Nanoc::Layout) })
    assert(site.templates.all? { |t| t.is_a?(Nanoc::Template) })
    assert(site.code.is_a?(Nanoc::Code))

    # Check whether site is set
    assert(site.pages.all? { |p| p.site == site })
    assert(site.page_defaults.site == site)
    assert(site.layouts.all? { |l| l.site == site })
    assert(site.templates.all? { |t| t.site == site })
    assert(site.code.site == site)

  end

  def test_config
    # Create site
    site = Nanoc::Site.new(
      :output_dir   => 'custom_output',
      :data_source  => 'test_data_source',
      :router       => 'test_router'
    )

    # Check
    assert_equal('custom_output',     site.config[:output_dir])
    assert_equal('test_data_source',  site.config[:data_source])
    assert_equal('test_router',       site.config[:router])

    # Create site
    site = Nanoc::Site.new({})

    # Check
    assert_equal('output',      site.config[:output_dir])
    assert_equal('filesystem',  site.config[:data_source])
    assert_equal('default',     site.config[:router])
  end

end
