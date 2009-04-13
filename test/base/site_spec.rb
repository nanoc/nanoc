require 'test/helper'

describe 'Nanoc3::Site#initialize' do

  include Nanoc3::TestHelpers

  it 'should merge default config' do
    site = Nanoc3::Site.new(:router => 'versioned')
    site.config.must_equal Nanoc3::Site::DEFAULT_CONFIG.merge(:router => 'versioned')
  end

  it 'should not raise under normal circumstances' do
    Nanoc3::Site.new({})
  end

  it 'should not raise for non-existant output directory' do
    Nanoc3::Site.new(:output_dir => 'fklsdhailfdjalghlkasdflhagjskajdf')
  end

  it 'should not raise for unknown data sources' do
    proc do
      Nanoc3::Site.new(:data_source => 'fklsdhailfdjalghlkasdflhagjskajdf')
    end
  end

  it 'should not raise for unknown routers' do
    proc do
      Nanoc3::Site.new(:router => 'fklsdhailfdjalghlkasdflhagjskajdf')
    end
  end

end

describe 'Nanoc::Site#load_data' do

  include Nanoc3::TestHelpers

  it 'should load the data source' do
    site = Nanoc3::Site.new({})

    # Mock data source
    data_source = mock
    data_source.expects(:loading).yields
    site.expects(:data_source).returns(data_source)

    # Mock load_* methods
    site.stubs(:load_code).with(false)
    site.stubs(:load_items)
    site.stubs(:load_layouts)

    # Load data
    site.load_data
  end

  it 'should call load_* methods' do
    site = Nanoc3::Site.new({})

    # Mock data source
    data_source = mock
    data_source.expects(:loading).yields
    site.stubs(:data_source).returns(data_source)

    # Mock load_* methods
    site.expects(:load_code).with(false)
    site.expects(:load_items)
    site.expects(:load_layouts)

    # Load data
    site.load_data
  end

  it 'should not load data twice if not forced' do
    site = Nanoc3::Site.new({})

    # Mock data source
    data_source = mock
    data_source.expects(:loading).once.yields
    site.expects(:data_source).returns(data_source)

    # Mock load_* methods
    site.expects(:load_code).with(false).once
    site.expects(:load_items).once
    site.expects(:load_layouts).once

    # Load data twice
    site.load_data
    site.load_data
  end

  it 'should load data twice if forced' do
    site = Nanoc3::Site.new({})

    # Mock data source
    data_source = mock
    data_source.expects(:loading).times(2).yields
    site.expects(:data_source).times(2).returns(data_source)

    # Mock load_* methods
    site.expects(:load_code).with(true).times(2)
    site.expects(:load_items).times(2)
    site.expects(:load_layouts).times(2)

    # Load data twice
    site.load_data(true)
    site.load_data(true)
  end

end

describe 'Nanoc::Site#code' do

  include Nanoc3::TestHelpers

  it 'should raise when data is not loaded yet' do
    site = Nanoc3::Site.new({})
    proc do
      site.code
    end.must_raise Nanoc3::Errors::DataNotYetAvailableError
  end

end

describe 'Nanoc::Site#items' do

  include Nanoc3::TestHelpers

  it 'should raise when data is not loaded yet' do
    site = Nanoc3::Site.new({})
    proc do
      site.items
    end.must_raise Nanoc3::Errors::DataNotYetAvailableError
  end

end

describe 'Nanoc::Site#layouts' do

  include Nanoc3::TestHelpers

  it 'should raise when data is not loaded yet' do
    site = Nanoc3::Site.new({})
    proc do
      site.layouts
    end.must_raise Nanoc3::Errors::DataNotYetAvailableError
  end

end

describe 'Nanoc::Site#compiler' do

  include Nanoc3::TestHelpers

  it 'should not raise under normal circumstances' do
    site = Nanoc3::Site.new({})
    site.compiler
  end

end

describe 'Nanoc::Site#router' do

  include Nanoc3::TestHelpers

  it 'should not raise for known routers' do
    site = Nanoc3::Site.new({})
    site.router
  end

  it 'should raise for unknown routers' do
    proc do
      site = Nanoc3::Site.new(:router => 'fklsdhailfdjalghlkasdflhagjskajdf')
      site.router
    end.must_raise Nanoc3::Errors::UnknownRouterError
  end

end

describe 'Nanoc::Site#data_source' do

  include Nanoc3::TestHelpers

  it 'should not raise for known data sources' do
    site = Nanoc3::Site.new({})
    site.data_source
  end

  it 'should raise for unknown data sources' do
    proc do
      site = Nanoc3::Site.new(:data_source => 'fklsdhailfdjalghlkasdflhagjskajdf')
      site.data_source
    end.must_raise Nanoc3::Errors::UnknownDataSourceError
  end

end
