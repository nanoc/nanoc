require 'test/helper'

describe 'Nanoc::Site#initialize' do

  # FIXME causes warnings for some odd reason

  # TODO implement should load code
  # TODO implement should not raise for custom routers

  before { global_setup    }
  after  { global_teardown }

  it 'should merge default config' do
    should.not.raise do
      site = Nanoc::Site.new(:router => 'versioned')
      site.config.should == Nanoc::Site::DEFAULT_CONFIG.merge(:router => 'versioned')
    end
  end

  it 'should not raise in normal situations' do
    should.not.raise do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'filesystem',
        :router       => 'default'
      )
    end
  end

  it 'should not raise for non-existant output directory' do
    should.not.raise do
      Nanoc::Site.new(
        :output_dir   => 'non_existant_output_dir',
        :data_source  => 'filesystem',
        :router       => 'default'
      )
    end
  end

  it 'should raise for unknown data sources' do
    should.raise(Nanoc::Errors::UnknownDataSourceError) do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'unknown_data_source',
        :router       => 'default'
      )
    end
  end

  it 'should raise for unknown routers' do
    should.raise(Nanoc::Errors::UnknownRouterError) do
      Nanoc::Site.new(
        :output_dir   => 'output',
        :data_source  => 'filesystem',
        :router       => 'unknown_router'
      )
    end
  end

  it 'should query the data source when loading data' do
    site = Nanoc::Site.new({})
    site.data_source.expects(:pages).returns([
      Nanoc::Page.new("Hi!",          {}, '/'),
      Nanoc::Page.new("Hello there.", {}, '/about/')
    ])
    site.data_source.expects(:page_defaults).returns(
      Nanoc::PageDefaults.new({ :foo => 'bar' })
    )
    site.data_source.expects(:assets).returns([
      Nanoc::Asset.new(File.open('/dev/null'), {}, '/something/')
    ])
    site.data_source.expects(:asset_defaults).returns(
      Nanoc::AssetDefaults.new({ :foo => 'baz' })
    )
    site.data_source.expects(:layouts).returns([
      Nanoc::Layout.new(
        'HEADER <%= @page.content %> FOOTER',
        { :filter => 'erb' },
        '/quux/'
      )
    ])
    site.load_data

    # Check classes
    site.page_defaults.should.be.an.instance_of  Nanoc::PageDefaults
    site.asset_defaults.should.be.an.instance_of Nanoc::AssetDefaults
    site.code.should.be.an.instance_of           Nanoc::Code
    site.pages.each     { |p| p.should.be.an.instance_of Nanoc::Page     }
    site.assets.each    { |p| p.should.be.an.instance_of Nanoc::Asset    }
    site.layouts.each   { |l| l.should.be.an.instance_of Nanoc::Layout   }

    # Check whether site is set
    site.page_defaults.site.should  == site
    site.asset_defaults.site.should == site
    site.code.site.should           == site
    site.pages.each     { |p| p.site.should == site }
    site.assets.each    { |p| p.site.should == site }
    site.layouts.each   { |l| l.site.should == site }
  end

end
