# frozen_string_literal: true

require 'helper'

class Nanoc::Core::SiteTest < Nanoc::TestCase
  def test_initialize_with_dir_without_config_yaml
    assert_raises(Nanoc::Core::ConfigLoader::NoConfigFileFoundError) do
      Nanoc::Core::SiteLoader.new.new_from_cwd
    end
  end

  def test_initialize_with_dir_with_config_yaml
    File.write('config.yaml', 'output_dir: public_html')
    site = Nanoc::Core::SiteLoader.new.new_from_cwd

    assert_equal Dir.getwd + '/public_html', site.config.output_dir
  end

  def test_initialize_with_dir_with_nanoc_yaml
    File.write('nanoc.yaml', 'output_dir: public_html')
    site = Nanoc::Core::SiteLoader.new.new_from_cwd

    assert_equal Dir.getwd + '/public_html', site.config.output_dir
  end

  def test_initialize_with_incomplete_data_source_config
    File.write('nanoc.yaml', 'data_sources: [{ items_root: "/bar/" }]')
    site = Nanoc::Core::SiteLoader.new.new_from_cwd

    assert_equal('filesystem', site.config[:data_sources][0][:type])
    assert_equal('/bar/', site.config[:data_sources][0][:items_root])
    assert_equal('/',     site.config[:data_sources][0][:layouts_root])
    assert_equal({},      site.config[:data_sources][0][:config])
  end

  def test_initialize_with_existing_parent_config_file
    File.write('nanoc.yaml', <<~EOF)
      output_dir: public_html
      parent_config_file: foo/foo.yaml
    EOF
    FileUtils.mkdir_p('foo')
    FileUtils.cd('foo') do
      File.write('foo.yaml', <<~EOF)
        parent_config_file: ../bar/bar.yaml
      EOF
    end
    FileUtils.mkdir_p('bar')
    FileUtils.cd('bar') do
      File.write('bar.yaml', <<~EOF)
        enable_output_diff: true
        foo: bar
        output_dir: output
      EOF
    end

    site = Nanoc::Core::SiteLoader.new.new_from_cwd

    assert_nil site.config[:parent_config_file]
    assert site.config[:enable_output_diff]
    assert_equal 'bar', site.config[:foo]
    assert_equal Dir.getwd + '/public_html', site.config.output_dir
  end

  def test_initialize_with_missing_parent_config_file
    File.write('nanoc.yaml', <<~EOF)
      parent_config_file: foo/foo.yaml
    EOF

    assert_raises(Nanoc::Core::ConfigLoader::NoParentConfigFileFoundError) do
      Nanoc::Core::SiteLoader.new.new_from_cwd
    end
  end

  def test_initialize_with_parent_config_file_cycle
    File.write('nanoc.yaml', <<~EOF)
      parent_config_file: foo/foo.yaml
    EOF
    FileUtils.mkdir_p('foo')
    FileUtils.cd('foo') do
      File.write('foo.yaml', <<~EOF)
        parent_config_file: ../nanoc.yaml
      EOF
    end

    assert_raises(Nanoc::Core::ConfigLoader::CyclicalConfigFileError) do
      Nanoc::Core::SiteLoader.new.new_from_cwd
    end
  end

  def test_identifier_classes
    Nanoc::CLI.run %w[create_site bar]
    FileUtils.cd('bar') do
      FileUtils.mkdir_p('content')
      FileUtils.mkdir_p('layouts')

      File.open('content/foo_bar.md', 'w') { |io| io << 'asdf' }
      File.open('layouts/detail.erb', 'w') { |io| io << 'asdf' }

      site = Nanoc::Core::SiteLoader.new.new_from_cwd

      site.items.each do |item|
        assert_instance_of Nanoc::Core::Identifier, item.identifier
      end

      site.layouts.each do |layout|
        assert_instance_of Nanoc::Core::Identifier, layout.identifier
      end
    end
  end

  def test_multiple_items_with_same_identifier
    with_site do
      File.write('content/sam.html', 'I am Sam!')
      FileUtils.mkdir_p('content/sam')
      File.write('content/sam/index.html', 'I am Sam, too!')

      assert_raises(Nanoc::Core::Site::DuplicateIdentifierError) do
        Nanoc::Core::SiteLoader.new.new_from_cwd
      end
    end
  end

  def test_multiple_layouts_with_same_identifier
    with_site do
      File.write('layouts/sam.html', 'I am Sam!')
      FileUtils.mkdir_p('layouts/sam')
      File.write('layouts/sam/index.html', 'I am Sam, too!')

      assert_raises(Nanoc::Core::Site::DuplicateIdentifierError) do
        Nanoc::Core::SiteLoader.new.new_from_cwd
      end
    end
  end
end
