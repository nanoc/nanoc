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

    site = Nanoc::Site.new('.')
    assert_nil site.config[:parent_config_file]
    assert site.config[:enable_output_diff]
    assert_equal 'bar', site.config[:foo]
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_missing_parent_config_file
    File.open('nanoc.yaml', 'w') do |io|
      io.write <<-EOF
parent_config_file: foo/foo.yaml
EOF
    end

    error = assert_raises(Nanoc::Errors::GenericTrivial) do
      site = Nanoc::Site.new('.')
    end
    assert_equal(
      "Could not find parent configuration file 'foo/foo.yaml'",
      error.message
    )
  end

  def test_initialize_with_parent_config_file_cycle
    File.open('nanoc.yaml', 'w') do |io|
      io.write <<-EOF
parent_config_file: foo/foo.yaml
EOF
    end
    FileUtils.mkdir_p('foo')
    FileUtils.cd('foo') do
      File.open('foo.yaml', 'w') do |io|
        io.write <<-EOF
parent_config_file: ../nanoc.yaml
EOF
      end
    end

    error = assert_raises(Nanoc::Errors::GenericTrivial) do
      site = Nanoc::Site.new('.')
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
