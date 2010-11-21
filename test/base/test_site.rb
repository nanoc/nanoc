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
    site.compiler.expects(:dsl).returns(dsl)

    # Create rules file
    File.open('Rules', 'w') do |io|
      io.write <<-EOF
compile '*' do
  # ... do nothing ...
end
EOF
    end

    # Load rules
    site.compiler.send :load_rules
  end

  def test_load_data_sources_first
    # Create site
    Nanoc3::CLI::Base.new.run([ 'create_site', 'bar' ])

    FileUtils.cd('bar') do
      # Create data source code
      File.open('lib/some_data_source.rb', 'w') do |io|
        io.write "class FooDataSource < Nanoc3::DataSource\n"
        io.write "  identifier :site_test_foo\n"
        io.write "  def items ; [ Nanoc3::Item.new('content', {}, '/foo/') ] ; end\n"
        io.write "end\n"
      end

      # Update configuration
      File.open('config.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  - type: site_test_foo"
      end

      # Create site
      site = Nanoc3::Site.new('.')
      site.load_data

      # Check
      assert_equal 1,       site.data_sources.size
      assert_equal '/foo/', site.items[0].identifier
    end
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

describe 'Nanoc3::Site#compiler' do

  include Nanoc3::TestHelpers

  it 'should not raise under normal circumstances' do
    site = Nanoc3::Site.new({})
    site.compiler
  end

end

describe 'Nanoc3::Site#data_sources' do

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
