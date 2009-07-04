# encoding: utf-8

require 'test/helper'

class Nanoc3::SiteTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_load_rules_with_existing_rules_file
    # Mock DSL
    dsl = mock
    dsl.expects(:compile).with('*')

    # Create site
    site = Nanoc3::Site.new({})
    site.expects(:dsl).returns(dsl)

    # Create rules file
    File.open('Rules', 'w') do |io|
      io.write <<-EOF
compile '*' do |rep|
  # ... do nothing ...
end
EOF
    end

    # Load rules
    site.send :load_rules
  end

  def test_load_rules_with_broken_rules_file
    # Mock DSL
    dsl = mock
    dsl.expects(:some_function_that_doesn_really_exist)
    dsl.expects(:weird_param_number_one)
    dsl.expects(:mysterious_param_number_two)

    # Create site
    site = Nanoc3::Site.new({})
    site.expects(:dsl).returns(dsl)

    # Create rules file
    File.open('Rules', 'w') do |io|
      io.write <<-EOF
some_function_that_doesn_really_exist(
weird_param_number_one,
mysterious_param_number_two
)
EOF
    end

    # Load rules
    site.send :load_rules
  end

end

describe 'Nanoc3::Site#initialize' do

  include Nanoc3::TestHelpers

  it 'should merge default config' do
    site = Nanoc3::Site.new(:foo => 'bar')
    site.config[:foo].must_equal 'bar'
    site.config[:output_dir].must_equal 'output'
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
    site.stubs(:load_rules)
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
    site.expects(:load_rules)
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
    site.expects(:load_rules)
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
    site.expects(:load_rules).times(2)
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
    end.must_raise Nanoc3::Errors::DataNotYetAvailable
  end

end

describe 'Nanoc::Site#items' do

  include Nanoc3::TestHelpers

  it 'should raise when data is not loaded yet' do
    site = Nanoc3::Site.new({})
    proc do
      site.items
    end.must_raise Nanoc3::Errors::DataNotYetAvailable
  end

end

describe 'Nanoc::Site#layouts' do

  include Nanoc3::TestHelpers

  it 'should raise when data is not loaded yet' do
    site = Nanoc3::Site.new({})
    proc do
      site.layouts
    end.must_raise Nanoc3::Errors::DataNotYetAvailable
  end

end

describe 'Nanoc::Site#compiler' do

  include Nanoc3::TestHelpers

  it 'should not raise under normal circumstances' do
    site = Nanoc3::Site.new({})
    site.compiler
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
    end.must_raise Nanoc3::Errors::UnknownDataSource
  end

end
