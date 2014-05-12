# encoding: utf-8

class Nanoc::SiteTest < Nanoc::TestCase

  def test_initialize_with_dir_without_config_yaml
    assert_raises(Nanoc::Errors::GenericTrivial) do
      Nanoc::SiteLoader.new.load
    end
  end

  def test_initialize_with_dir_with_config_yaml
    File.write('config.yaml', 'output_dir: public_html')
    site = Nanoc::SiteLoader.new.load
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_dir_with_nanoc_yaml
    File.write('nanoc.yaml', 'output_dir: public_html')
    site = Nanoc::SiteLoader.new.load
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_incomplete_data_source_config
    yaml = YAML.dump(:data_sources => [ { :type => 'filesystem', :items_root => '/bar/' } ])
    File.write('nanoc.yaml', yaml)
    site = Nanoc::SiteLoader.new.load
    assert_equal('filesystem', site.config[:data_sources][0][:type])
    assert_equal('/bar/',      site.config[:data_sources][0][:items_root])
    assert_equal('/',          site.config[:data_sources][0][:layouts_root])
    assert_equal({},           site.config[:data_sources][0][:config])
  end

  def test_initialize_with_existing_parent_config_file
    File.open('nanoc.yaml', 'w') do |io|
      io.write <<-EOF
output_dir: public_html
parent_config_file: foo/foo.yaml
EOF
    end
    FileUtils.mkdir_p('foo')
    FileUtils.cd('foo') do
      File.open('foo.yaml', 'w') do |io|
        io.write <<-EOF
parent_config_file: ../bar/bar.yaml
EOF
      end
    end
    FileUtils.mkdir_p('bar')
    FileUtils.cd('bar') do
      File.open('bar.yaml', 'w') do |io|
        io.write <<-EOF
enable_output_diff: true
foo: bar
output_dir: output
EOF
      end
    end

    site = Nanoc::SiteLoader.new.load
    assert_nil site.config[:parent_config_file]
    assert site.config[:enable_output_diff]
    assert_equal 'bar', site.config[:foo]
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_missing_parent_config_file
    File.write('nanoc.yaml', 'parent_config_file: foo/foo.yaml')

    error = assert_raises(Nanoc::Errors::GenericTrivial) do
      site = Nanoc::SiteLoader.new.load
    end
    assert_equal(
      "Could not find parent configuration file 'foo/foo.yaml'",
      error.message
    )
  end

  def test_initialize_with_parent_config_file_cycle
    File.write('nanoc.yaml', 'parent_config_file: foo/foo.yaml')
    FileUtils.mkdir_p('foo')
    File.write('foo/foo.yaml', 'parent_config_file: ../nanoc.yaml')

    error = assert_raises(Nanoc::Errors::GenericTrivial) do
      site = Nanoc::SiteLoader.new.load
    end
    assert_equal(
      "Cycle detected. Could not use parent configuration file '../nanoc.yaml'",
      error.message
    )
  end

  def test_load_rules_with_existing_rules_file
    # Mock DSL
    dsl = mock
    dsl.stubs(:rules_filename)
    dsl.stubs(:rules_filename=)
    dsl.expects(:compile).with('*')

    # Create site
    site = Nanoc::Site.new({})
    site.compiler.rules_collection.stubs(:dsl).returns(dsl)

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
      File.open('nanoc.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  - type: site_test_foo"
      end

      # Create site
      site = Nanoc::SiteLoader.new.load

      # Check
      assert_equal 1,      site.data_sources.size
      assert_equal '/foo', site.items[0].identifier.to_s
    end
  end

  def test_setup_child_parent_links
    Nanoc::CLI.run %w( create_site bar)
    FileUtils.cd('bar') do
      FileUtils.mkdir_p('content/parent')
      FileUtils.mkdir_p('content/parent/bar')

      File.write('content/parent.md', 'Hi!')
      File.write('content/parent/foo.md', 'Hi!')
      File.write('content/parent/bar.md', 'Hi!')
      File.write('content/parent/bar/qux.md', 'Hi!')

      site = Nanoc::SiteLoader.new.load

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

  def test_multiple_items_with_same_identifier
    in_site do
      File.write('content/sam.html', 'I am Sam!')
      FileUtils.mkdir_p('content/sam')
      File.write('content/sam/index.html', 'I am Sam, too!')

      assert_raises(Nanoc::Errors::DuplicateIdentifier) do
        Nanoc::SiteLoader.new.load
      end
    end
  end

  def test_multiple_layouts_with_same_identifier
    in_site do
      File.write('layouts/sam.html', 'I am Sam!')
      FileUtils.mkdir_p('layouts/sam')
      File.write('layouts/sam/index.html', 'I am Sam, too!')

      assert_raises(Nanoc::Errors::DuplicateIdentifier) do
        Nanoc::SiteLoader.new.load
      end
    end
  end

end

describe 'Nanoc::Site#initialize' do

  include Nanoc::TestHelpers

  let(:config)    { {} }
  let(:site_name) { 'site-initialize-test' }

  before do
    in_site(name: site_name) do
      File.write('nanoc.yaml', YAML.dump(config))
    end
  end

  describe 'with customized config' do

    let(:config) do
      { foo: 'bar' }
    end

    it 'should merge default config' do
      in_site(name: site_name) do
        site = Nanoc::SiteLoader.new.load
        site.config[:foo].must_equal 'bar'
        site.config[:output_dir].must_equal 'output'
      end
    end

  end

  describe 'with non-existant output directory' do

    let(:config) do
      { output_dir: 'fklsdhailfdjalghlkasdflhagjskajdf' }
    end

    it 'should not raise' do
      in_site(name: site_name) do
        Nanoc::SiteLoader.new.load
      end
    end

  end

  describe 'with unknown data sources' do

    let(:config) do
      # FIXME this test makes no sense
      { data_source: 'fklsdhailfdjalghlkasdflhagjskajdf' }
    end

    it 'should not raise' do
      in_site(name: site_name) do
        Nanoc::SiteLoader.new.load
      end
    end

  end

end

describe 'Nanoc::Site#data_sources' do

  include Nanoc::TestHelpers

  it 'should raise for unknown data sources' do
    proc do
      in_site do
        File.open('nanoc.yaml', 'w') do |io|
          io.write "data_sources:\n"
          io.write "  -\n"
          io.write "    type: sdjhkgfdsdfghj\n"
        end
        Nanoc::SiteLoader.new.load
      end
    end.must_raise Nanoc::Errors::UnknownDataSource
  end

  it 'should also use the toplevel config for data sources' do
    in_site do
      File.open('nanoc.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  -\n"
        io.write "    type: filesystem\n"
        io.write "    aaa: one\n"
        io.write "    config:\n"
        io.write "      bbb: two\n"
      end

      site = Nanoc::SiteLoader.new.load
      data_sources = site.data_sources

      assert data_sources.first.config[:aaa] = 'one'
      assert data_sources.first.config[:bbb] = 'two'
    end
  end

end
