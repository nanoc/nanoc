# encoding: utf-8

class Nanoc::SiteTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_initialize_with_dir_without_config_yaml
    assert_raises(Errno::ENOENT) do
      site = Nanoc::Site.new('.')
    end
  end

  def test_initialize_with_dir_with_config_yaml
    File.open('config.yaml', 'w') { |io| io.write('output_dir: public_html') }
    site = Nanoc::Site.new('.')
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_config_hash
    site = Nanoc::Site.new(:foo => 'bar')
    assert_equal 'bar', site.config[:foo]
  end

  def test_initialize_with_incomplete_data_source_config
    site = Nanoc::Site.new(:data_sources => [ { :type => 'foo', :items_root => '/bar/' } ])
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
    site = Nanoc::Site.new({})
    site.compiler.rules_collection.expects(:dsl).returns(dsl)

    # Create rules file
    File.open('Rules', 'w') do |io|
      io.write <<-EOF
compile '*' do
  # ... do nothing ...
end
EOF
    end

    # Load rules
    site.compiler.rules_collection.load
  end

  def test_load_data_sources_first
    # Create site
    Nanoc::CLI.run %w( create_site bar)

    FileUtils.cd('bar') do
      # Create data source code
      File.open('lib/some_data_source.rb', 'w') do |io|
        io.write "class FooDataSource < Nanoc::DataSource\n"
        io.write "  identifier :site_test_foo\n"
        io.write "  def items ; [ Nanoc::Item.new('content', {}, '/foo/') ] ; end\n"
        io.write "end\n"
      end

      # Update configuration
      File.open('config.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  - type: site_test_foo"
      end

      # Create site
      site = Nanoc::Site.new('.')
      site.load_data

      # Check
      assert_equal 1,       site.data_sources.size
      assert_equal '/foo/', site.items[0].identifier
    end
  end

  def test_setup_child_parent_links
    Nanoc::CLI.run %w( create_site bar)
    FileUtils.cd('bar') do
      Nanoc::CLI.run %w( create_item /parent/ )
      Nanoc::CLI.run %w( create_item /parent/foo/ )
      Nanoc::CLI.run %w( create_item /parent/bar/ )
      Nanoc::CLI.run %w( create_item /parent/bar/qux/ )

      site = Nanoc::Site.new('.')

      root   = site.items.find { |i| i.identifier == '/' }
      style  = site.items.find { |i| i.identifier == '/stylesheet/' }
      parent = site.items.find { |i| i.identifier == '/parent/' }
      foo    = site.items.find { |i| i.identifier == '/parent/foo/' }
      bar    = site.items.find { |i| i.identifier == '/parent/bar/' }
      qux    = site.items.find { |i| i.identifier == '/parent/bar/qux/' }

      assert_equal Set.new([ parent, style ]), Set.new(root.children)
      assert_equal Set.new([ foo, bar ]),      Set.new(parent.children)
      assert_equal Set.new([ qux ]),           Set.new(bar.children)

      assert_equal nil,    root.parent
      assert_equal root,   parent.parent
      assert_equal parent, foo.parent
      assert_equal parent, bar.parent
      assert_equal bar,    qux.parent
    end
  end

end

describe 'Nanoc::Site#initialize' do

  include Nanoc::TestHelpers

  it 'should merge default config' do
    site = Nanoc::Site.new(:foo => 'bar')
    site.config[:foo].must_equal 'bar'
    site.config[:output_dir].must_equal 'output'
  end

  it 'should not raise under normal circumstances' do
    Nanoc::Site.new({})
  end

  it 'should not raise for non-existant output directory' do
    Nanoc::Site.new(:output_dir => 'fklsdhailfdjalghlkasdflhagjskajdf')
  end

  it 'should not raise for unknown data sources' do
    proc do
      Nanoc::Site.new(:data_source => 'fklsdhailfdjalghlkasdflhagjskajdf')
    end
  end

end

describe 'Nanoc::Site#compiler' do

  include Nanoc::TestHelpers

  it 'should not raise under normal circumstances' do
    site = Nanoc::Site.new({})
    site.compiler
  end

end

describe 'Nanoc::Site#data_sources' do

  include Nanoc::TestHelpers

  it 'should not raise for known data sources' do
    site = Nanoc::Site.new({})
    site.data_sources
  end

  it 'should raise for unknown data sources' do
    proc do
      site = Nanoc::Site.new(
        :data_sources => [
          { :type => 'fklsdhailfdjalghlkasdflhagjskajdf' }
        ]
      )
      site.data_sources
    end.must_raise Nanoc::Errors::UnknownDataSource
  end

  it 'should also use the toplevel config for data sources' do
    with_site do
      File.open('config.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  -\n"
        io.write "    type: filesystem_unified\n"
        io.write "    aaa: one\n"
        io.write "    config:\n"
        io.write "      bbb: two\n"
      end

      site = Nanoc::Site.new('.')
      data_sources = site.data_sources

      assert data_sources.first.config[:aaa] = 'one'
      assert data_sources.first.config[:bbb] = 'two'
    end
  end

end
