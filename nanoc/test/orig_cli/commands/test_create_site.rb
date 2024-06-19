# frozen_string_literal: true

require 'helper'

class Nanoc::CLI::Commands::CreateSiteTest < Nanoc::TestCase
  def test_create_site_with_existing_name
    Nanoc::CLI.run %w[create_site foo]
    assert_raises(::Nanoc::Core::TrivialError) do
      Nanoc::CLI.run %w[create_site foo]
    end
  end

  def test_can_compile_new_site
    Nanoc::CLI.run %w[create_site foo]

    FileUtils.cd('foo') do
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)
    end
  end

  def test_can_compile_new_site_in_current_directory
    FileUtils.mkdir('foo')

    FileUtils.cd('foo') do
      Nanoc::CLI.run %w[create_site ./]
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)
    end
  end

  def test_can_compile_new_site_with_binary_items
    Nanoc::CLI.run %w[create_site foo]

    FileUtils.cd('foo') do
      File.open('content/blah', 'w') { |io| io << 'asdf' }
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      assert File.file?('output/blah')
    end
  end

  def test_can_compile_site_in_nonempty_directory
    FileUtils.mkdir('foo')
    FileUtils.touch(File.join('foo', 'SomeFile.txt'))
    Nanoc::CLI.run %w[create_site foo --force]

    FileUtils.cd('foo') do
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)
    end
  end

  def test_compiled_site_output
    FileUtils.mkdir('foo')
    FileUtils.touch(File.join('foo', 'SomeFile.txt'))
    Nanoc::CLI.run %w[create_site foo --force]

    FileUtils.cd('foo') do
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      assert File.file?('output/index.html')
    end
  end

  def test_default_encoding
    unless defined?(Encoding)
      skip 'No Encoding class'
    end

    original_encoding = Encoding.default_external
    Encoding.default_external = 'ISO-8859-1' # ew!

    Nanoc::CLI.run %w[create_site foo]

    FileUtils.cd('foo') do
      # Try with encoding = default encoding = utf-8
      File.write('content/index.html', 'Hello ' + 0xD6.chr + "!\n")
      exception = assert_raises(Nanoc::DataSources::Filesystem::Errors::InvalidEncoding) do
        Nanoc::Core::SiteLoader.new.new_from_cwd
      end

      assert_equal 'Could not read content/index.html because the file is not valid UTF-8.', exception.message

      # Try with encoding = specific
      File.open('nanoc.yaml', 'w') do |io|
        io.write("string_pattern_type: glob\n")
        io.write("data_sources:\n")
        io.write("  -\n")
        io.write("    type: filesystem\n")
        io.write("    identifier_type: full\n")
      end
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)
    end
    FileUtils
  ensure
    Encoding.default_external = original_encoding
  end

  def test_new_site_has_correct_stylesheets
    Nanoc::CLI.run %w[create_site foo]
    FileUtils.cd('foo') do
      Nanoc::CLI.run %w[compile]

      assert File.file?('content/stylesheet.css')
      assert_match(/\/stylesheet.css/, File.read('output/index.html'))
    end
  end

  def test_new_site_prunes_by_default
    FileUtils.mkdir('foo')
    FileUtils.touch(File.join('foo', 'SomeFile.txt'))
    Nanoc::CLI.run %w[create_site foo --force]

    FileUtils.cd('foo') do
      File.write('output/blah.txt', 'stuff')

      Nanoc::CLI.run %w[compile]

      refute File.file?('output/blah.txt')
    end
  end

  def test_default_site_routes_items_properly
    Nanoc::CLI.run %w[create_site foo]

    FileUtils.cd('foo') do
      FileUtils.mkdir_p('content/bar')
      File.write('content/index.html', 'Index')
      File.write('content/foo.html', 'Foo')
      File.write('content/bar/index.html', 'Bar Index')
      File.write('content/bar/qux.html', 'Bar Qux')

      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      assert File.file?('output/index.html')
      assert File.file?('output/foo/index.html')
      assert File.file?('output/bar/index.html')
      assert File.file?('output/bar/qux/index.html')
      assert_match(/Index/, File.read('output/index.html'))
      assert_match(/Foo/, File.read('output/foo/index.html'))
      assert_match(/Bar Index/, File.read('output/bar/index.html'))
      assert_match(/Bar Qux/, File.read('output/bar/qux/index.html'))
    end
  end

  def test_create_site_gemfile
    Nanoc::CLI.run %w[create_site foo]

    FileUtils.cd('foo') do
      assert File.file?('Gemfile')
      assert_match(/^gem 'nanoc', '~> 4.13'$/, File.read('Gemfile'))
    end
  end
end
