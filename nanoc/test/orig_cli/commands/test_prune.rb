# frozen_string_literal: true

require 'helper'

class Nanoc::CLI::Commands::PruneTest < Nanoc::TestCase
  def test_run_without_yes
    with_site do |_site|
      # Set output dir
      File.write('nanoc.yaml', "output_dir: output2\nstring_pattern_type: legacy\n")
      FileUtils.mkdir_p('output2')

      # Create source files
      File.write('content/index.html', 'stuff')

      # Create output files
      File.write('output2/foo.html', 'this is a foo.')
      File.write('output2/index.html', 'this is a index.')

      assert_raises SystemExit do
        Nanoc::CLI.run %w[prune]
      end

      assert File.file?('output2/index.html')
      assert File.file?('output2/foo.html')
    end
  end

  def test_run_with_yes
    with_site do |_site|
      # Set output dir
      File.open('nanoc.yaml', 'w') do |io|
        io << 'output_dir: output2' << "\n"
        io << 'string_pattern_type: legacy' << "\n"
        io << 'data_sources:' << "\n"
        io << '  -' << "\n"
        io << '    type: filesystem' << "\n"
        io << '    identifier_type: legacy' << "\n"
      end
      FileUtils.mkdir_p('output2')

      # Create source files
      File.write('content/index.html', 'stuff')

      # Create output files
      File.write('output2/foo.html', 'this is a foo.')
      File.write('output2/index.html', 'this is a index.')

      io = capturing_stdio do
        Nanoc::CLI.run %w[prune --yes]
      end

      assert_match %r{^\s+delete  output2/foo\.html$}, io[:stdout]

      assert File.file?('output2/index.html')
      refute File.file?('output2/foo.html')
    end
  end

  def test_run_with_dry_run
    with_site do |_site|
      # Set output dir
      File.write('nanoc.yaml', "string_pattern_type: legacy\noutput_dir: output2")
      FileUtils.mkdir_p('output2')

      # Create source files
      File.write('content/index.html', 'stuff')

      # Create output files
      File.write('output2/foo.html', 'this is a foo.')
      File.write('output2/index.html', 'this is a index.')

      io = capturing_stdio do
        Nanoc::CLI.run %w[prune --dry-run]
      end

      assert_match %r{^\s+delete  \(dry run\) output2/index\.html$}, io[:stdout]
      assert_match %r{^\s+delete  \(dry run\) output2/foo\.html$}, io[:stdout]

      assert File.file?('output2/index.html')
      assert File.file?('output2/foo.html')
    end
  end

  def test_run_with_exclude
    with_site do |_site|
      # Set output dir
      File.open('nanoc.yaml', 'w') do |io|
        io << 'prune:' << "\n"
        io << '  exclude: [ "good-dir", "good-file.html" ]' << "\n"
        io << 'string_pattern_type: legacy' << "\n"
        io << 'data_sources:' << "\n"
        io << '  -' << "\n"
        io << '    type: filesystem' << "\n"
        io << '    identifier_type: legacy' << "\n"
      end
      FileUtils.mkdir_p('output')

      # Create source files
      File.write('content/index.html', 'stuff')

      # Create output files
      FileUtils.mkdir_p('output/good-dir')
      FileUtils.mkdir_p('output/bad-dir')
      File.write('output/good-file.html', 'stuff')
      File.write('output/good-dir/blah', 'stuff')
      File.write('output/bad-file.html', 'stuff')
      File.write('output/bad-dir/blah', 'stuff')
      File.write('output/index.html', 'stuff')

      Nanoc::CLI.run %w[prune --yes]

      assert File.file?('output/index.html')
      assert File.file?('output/good-dir/blah')
      assert File.file?('output/good-file.html')
      refute File.file?('output/bad-dir/blah')
      refute File.file?('output/bad-file.html')
    end
  end

  def test_run_with_symlink_to_output_dir
    skip_unless_symlinks_supported

    if defined?(JRUBY_VERSION)
      skip 'JRuby has buggy File.find behavior (see https://github.com/jruby/jruby/issues/1647)'
    end

    if Nanoc::Core.on_windows?
      skip 'Symlinks to output dirs are currently not supported on Windows.'
    end

    with_site do |_site|
      # Set output dir
      FileUtils.rm_rf('output')
      FileUtils.mkdir_p('output-real')
      File.symlink('output-real', 'output')

      # Create source files
      File.write('content/index.html', 'stuff')

      # Create output files
      FileUtils.mkdir_p('output-real/some-dir')
      File.write('output-real/some-file.html', 'stuff')
      File.write('output-real/index.html', 'stuff')

      Nanoc::CLI.run %w[prune --yes]

      assert File.file?('output-real/index.html')
      refute File.directory?('output-real/some-dir')
      refute File.file?('output-real/some-file.html')
    end
  end

  def test_run_with_nested_empty_dirs
    with_site do |_site|
      # Set output dir
      File.write('nanoc.yaml', 'output_dir: output')
      FileUtils.mkdir_p('output')

      # Create output files
      FileUtils.mkdir_p('output/a/b/c')
      File.write('output/a/b/c/index.html', 'stuff')

      Nanoc::CLI.run %w[prune --yes]

      refute File.file?('output/a/b/c/index.html')
      refute File.directory?('output/a/b/c')
      refute File.directory?('output/a/b')
      refute File.directory?('output/a')
    end
  end
end
