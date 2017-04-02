require 'helper'

class Nanoc::Int::SiteTest < Nanoc::TestCase
  def test_initialize_with_dir_without_config_yaml
    assert_raises(Nanoc::Int::ConfigLoader::NoConfigFileFoundError) do
      Nanoc::Int::SiteLoader.new.new_from_cwd
    end
  end

  def test_initialize_with_dir_with_config_yaml
    File.open('config.yaml', 'w') { |io| io.write('output_dir: public_html') }
    site = Nanoc::Int::SiteLoader.new.new_from_cwd
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_dir_with_nanoc_yaml
    File.open('nanoc.yaml', 'w') { |io| io.write('output_dir: public_html') }
    site = Nanoc::Int::SiteLoader.new.new_from_cwd
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_config_hash
    site = Nanoc::Int::SiteLoader.new.new_with_config(foo: 'bar')
    assert_equal 'bar', site.config[:foo]
  end

  def test_initialize_with_incomplete_data_source_config
    site = Nanoc::Int::SiteLoader.new.new_with_config(data_sources: [{ items_root: '/bar/' }])
    assert_equal('filesystem', site.config[:data_sources][0][:type])
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

    site = Nanoc::Int::SiteLoader.new.new_from_cwd
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

    assert_raises(Nanoc::Int::ConfigLoader::NoParentConfigFileFoundError) do
      Nanoc::Int::SiteLoader.new.new_from_cwd
    end
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

    assert_raises(Nanoc::Int::ConfigLoader::CyclicalConfigFileError) do
      Nanoc::Int::SiteLoader.new.new_from_cwd
    end
  end

  def test_identifier_classes
    Nanoc::CLI.run %w[create_site bar]
    FileUtils.cd('bar') do
      FileUtils.mkdir_p('content')
      FileUtils.mkdir_p('layouts')

      File.open('content/foo_bar.md', 'w') { |io| io << 'asdf' }
      File.open('layouts/detail.erb', 'w') { |io| io << 'asdf' }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd

      site.items.each do |item|
        assert_equal Nanoc::Identifier, item.identifier.class
      end

      site.layouts.each do |layout|
        assert_equal Nanoc::Identifier, layout.identifier.class
      end
    end
  end

  def test_multiple_items_with_same_identifier
    with_site do
      File.open('content/sam.html', 'w') { |io| io.write('I am Sam!') }
      FileUtils.mkdir_p('content/sam')
      File.open('content/sam/index.html', 'w') { |io| io.write('I am Sam, too!') }

      assert_raises(Nanoc::Int::Errors::DuplicateIdentifier) do
        Nanoc::Int::SiteLoader.new.new_from_cwd
      end
    end
  end

  def test_multiple_layouts_with_same_identifier
    with_site do
      File.open('layouts/sam.html', 'w') { |io| io.write('I am Sam!') }
      FileUtils.mkdir_p('layouts/sam')
      File.open('layouts/sam/index.html', 'w') { |io| io.write('I am Sam, too!') }

      assert_raises(Nanoc::Int::Errors::DuplicateIdentifier) do
        Nanoc::Int::SiteLoader.new.new_from_cwd
      end
    end
  end
end
