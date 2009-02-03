require 'helper'

class Nanoc::SiteTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestDataSource < Nanoc::DataSource

    identifier :test_data_source

    def code ; Nanoc::Code.new('') ; end

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
      Nanoc::Defaults.new({ :foo => 'bar' })
    end

    def assets
      [
        Nanoc::Asset.new(File.open('/dev/null'), {}, '/something/')
      ]
    end

    def asset_defaults
      Nanoc::Defaults.new({ :foo => 'baz' })
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

    def code
      Nanoc::Code.new("def something_random ; 'something random, yah' ; end")
    end

  end

  class TestEarlyLoadingCodeDataSource < Nanoc::DataSource

    identifier :early_loading_code_data_source

    def pages
      [
        Nanoc::Page.new("Hi!",          {}, '/'),
        Nanoc::Page.new("Hello there.", {}, '/about/')
      ]
    end

    def page_defaults
      Nanoc::Defaults.new({ :foo => 'bar' })
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

    def code
      Nanoc::Code.new(
        "class TestEarlyLoadingCodeRouter < Nanoc::Router\n" +
        "  identifier :early_loading_code_router\n" +
        "  def web_path_for(page)  ; 'web path'  ; end\n" +
        "  def disk_path_for(page) ; 'disk path' ; end\n" +
        "end"
      )
    end

  end

  def test_initialize_custom_router
    assert_nothing_raised do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'early_loading_code_data_source',
        :router       => 'early_loading_code_router'
      )
    end
  end

end
