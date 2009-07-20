# encoding: utf-8

require 'test/helper'

class Nanoc3::SiteTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_initialize_with_dir_without_config_yaml
    assert_raises(Errno::ENOENT) do
      site = Nanoc3::Site.new('.')
    end
  end

  def test_initialize_with_dir_with_config_yaml
    File.open('config.yaml', 'w') { |io| io.write('output_dir: public_html') }
    site = Nanoc3::Site.new('.')
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_config_hash
    site = Nanoc3::Site.new(:foo => 'bar')
    assert_equal 'bar', site.config[:foo]
  end

  def test_initialize_with_incomplete_data_source_config
    site = Nanoc3::Site.new(:data_sources => [ { :type => 'foo', :items_root => '/bar/' } ])
    assert_equal('foo',   site.config[:data_sources][0][:type])
    assert_equal('/bar/', site.config[:data_sources][0][:items_root])
    assert_equal('/',     site.config[:data_sources][0][:layouts_root])
    assert_equal({},      site.config[:data_sources][0][:config])
  end

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
compile '*' do
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

    # Mock data sources
    data_sources = [ mock, mock, mock ]
    data_sources.each { |ds| ds.expects(:use)   }
    data_sources.each { |ds| ds.expects(:unuse) }
    site.stubs(:data_sources).returns(data_sources)

    # Mock load_* methods
    site.stubs(:load_code_snippets).with(false)
    site.stubs(:load_rules)
    site.stubs(:load_items)
    site.stubs(:load_layouts)
    site.expects(:link_everything_to_site)
    site.expects(:setup_child_parent_links)
    site.expects(:build_reps)
    site.expects(:route_reps)

    # Load data
    site.load_data
  end

  it 'should call the preprocessor' do
    site = Nanoc3::Site.new({})

    # Mock data sources
    data_sources = [ mock, mock, mock ]
    data_sources.each { |ds| ds.expects(:use)   }
    data_sources.each { |ds| ds.expects(:unuse) }
    site.stubs(:data_sources).returns(data_sources)

    # Mock load_* methods
    site.expects(:load_code_snippets).with(false)
    site.expects(:load_rules)
    site.expects(:load_items)
    site.expects(:load_layouts)
    site.expects(:link_everything_to_site)
    site.expects(:setup_child_parent_links)
    site.expects(:build_reps)
    site.expects(:route_reps)

    # Mock preprocessor
    preprocessor = lambda { }
    site.expects(:preprocessor).times(2).returns(preprocessor)

    # Load data
    site.load_data
  end

  it 'should call load_* methods' do
    site = Nanoc3::Site.new({})

    # Mock data sources
    data_sources = [ mock, mock, mock ]
    data_sources.each { |ds| ds.expects(:use)   }
    data_sources.each { |ds| ds.expects(:unuse) }
    site.stubs(:data_sources).returns(data_sources)

    # Mock load_* methods
    site.expects(:load_code_snippets).with(false)
    site.expects(:load_rules)
    site.expects(:load_items)
    site.expects(:load_layouts)
    site.expects(:link_everything_to_site)
    site.expects(:setup_child_parent_links)
    site.expects(:build_reps)
    site.expects(:route_reps)

    # Load data
    site.load_data
  end

  it 'should not load data twice if not forced' do
    site = Nanoc3::Site.new({})

    # Mock data sources
    data_sources = [ mock, mock, mock ]
    data_sources.each { |ds| ds.expects(:use)   }
    data_sources.each { |ds| ds.expects(:unuse) }
    site.stubs(:data_sources).returns(data_sources)

    # Mock load_* methods
    site.expects(:load_code_snippets).with(false).once
    site.expects(:load_rules)
    site.expects(:load_items).once
    site.expects(:load_layouts).once
    site.expects(:link_everything_to_site)
    site.expects(:setup_child_parent_links).once
    site.expects(:build_reps).once
    site.expects(:route_reps).once

    # Load data twice
    site.load_data
    site.load_data
  end

  it 'should load data twice if forced' do
    site = Nanoc3::Site.new({})

    # Mock data sources
    data_sources = [ mock, mock, mock ]
    data_sources.each { |ds| ds.expects(:use).times(2)   }
    data_sources.each { |ds| ds.expects(:unuse).times(2) }
    site.stubs(:data_sources).returns(data_sources)

    # Mock load_* methods
    site.expects(:load_code_snippets).with(true).times(2)
    site.expects(:load_rules).times(2)
    site.expects(:load_items).times(2)
    site.expects(:load_layouts).times(2)
    site.expects(:link_everything_to_site).times(2)
    site.expects(:setup_child_parent_links).times(2)
    site.expects(:build_reps).times(2)
    site.expects(:route_reps).times(2)

    # Load data twice
    site.load_data(true)
    site.load_data(true)
  end

end

describe 'Nanoc::Site#code_snippets' do

  include Nanoc3::TestHelpers

  it 'should raise when data is not loaded yet' do
    site = Nanoc3::Site.new({})
    proc do
      site.code_snippets
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

describe 'Nanoc::Site#data_sources' do

  include Nanoc3::TestHelpers

  it 'should not raise for known data sources' do
    site = Nanoc3::Site.new({})
    site.data_sources
  end

  it 'should raise for unknown data sources' do
    proc do
      site = Nanoc3::Site.new(
        :data_sources => [
          { :type => 'fklsdhailfdjalghlkasdflhagjskajdf' }
        ]
      )
      site.data_sources
    end.must_raise Nanoc3::Errors::UnknownDataSource
  end

end
