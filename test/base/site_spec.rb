require 'test/helper'

describe 'Nanoc::Site#initialize' do

  # FIXME causes warnings for some odd reason

  # TODO implement should load code
  # TODO implement should not raise for custom routers

  before { global_setup    }
  after  { global_teardown }

  it 'should merge default config' do
    site = Nanoc::Site.new(:router => 'versioned')
    site.config.must_equal Nanoc::Site::DEFAULT_CONFIG.merge(:router => 'versioned')
  end

  it 'should not raise in normal situations' do
    Nanoc::Site.new(
      :output_dir   => 'output',
      :data_source  => 'filesystem',
      :router       => 'default'
    )
  end

  it 'should not raise for non-existant output directory' do
    Nanoc::Site.new(
      :output_dir   => 'non_existant_output_dir',
      :data_source  => 'filesystem',
      :router       => 'default'
    )
  end

  it 'should raise for unknown data sources' do
    proc do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'unknown_data_source',
        :router       => 'default'
      )
    end.must_raise Nanoc::Errors::UnknownDataSourceError
  end

  it 'should raise for unknown routers' do
    proc do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'filesystem',
        :router       => 'unknown_router'
      )
    end.must_raise Nanoc::Errors::UnknownRouterError
  end

  it 'should query the data source when loading data' do
    site = Nanoc::Site.new({}, :load_data => false)
    site.data_source.expects(:pages).returns([
      Nanoc::Page.new("Hi!",          {}, '/'),
      Nanoc::Page.new("Hello there.", {}, '/about/')
    ])
    site.data_source.expects(:assets).returns([
      Nanoc::Asset.new(File.open('/dev/null'), {}, '/something/')
    ])
    site.data_source.expects(:layouts).returns([
      Nanoc::Layout.new(
        'HEADER <%= @page.content %> FOOTER',
        { :filter => 'erb' },
        '/quux/'
      )
    ])
    site.load_data

    # Check classes
    site.code.must_be_instance_of Nanoc::Code
    site.pages.each   { |p| p.must_be_instance_of Nanoc::Page     }
    site.assets.each  { |p| p.must_be_instance_of Nanoc::Asset    }
    site.layouts.each { |l| l.must_be_instance_of Nanoc::Layout   }

    # Check whether site is set
    site.code.site.must_equal           site
    site.pages.each     { |p| p.site.must_equal site }
    site.assets.each    { |p| p.site.must_equal site }
    site.layouts.each   { |l| l.site.must_equal site }
  end

end
