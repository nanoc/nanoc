require 'helper'

class Nanoc::CLI::Commands::PruneTest < Nanoc::TestCase
  def test_run_without_yes
    with_site do |_site|
      # Set output dir
      File.open('nanoc.yaml', 'w') { |io| io.write "output_dir: output2\nstring_pattern_type: legacy\n" }
      FileUtils.mkdir_p('output2')

      # Create source files
      File.open('content/index.html', 'w') { |io| io.write 'stuff' }

      # Create output files
      File.open('output2/foo.html', 'w')   { |io| io.write 'this is a foo.' }
      File.open('output2/index.html', 'w') { |io| io.write 'this is a index.' }

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
      File.open('content/index.html', 'w') { |io| io.write 'stuff' }

      # Create output files
      File.open('output2/foo.html', 'w')   { |io| io.write 'this is a foo.' }
      File.open('output2/index.html', 'w') { |io| io.write 'this is a index.' }

      Nanoc::CLI.run %w[prune --yes]

      assert File.file?('output2/index.html')
      assert !File.file?('output2/foo.html')
    end
  end

  def test_run_with_dry_run
    with_site do |_site|
      # Set output dir
      File.open('nanoc.yaml', 'w') { |io| io.write "string_pattern_type: legacy\noutput_dir: output2" }
      FileUtils.mkdir_p('output2')

      # Create source files
      File.open('content/index.html', 'w') { |io| io.write 'stuff' }

      # Create output files
      File.open('output2/foo.html', 'w')   { |io| io.write 'this is a foo.' }
      File.open('output2/index.html', 'w') { |io| io.write 'this is a index.' }

      Nanoc::CLI.run %w[prune --dry-run]

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
      File.open('content/index.html', 'w') { |io| io.write 'stuff' }

      # Create output files
      FileUtils.mkdir_p('output/good-dir')
      FileUtils.mkdir_p('output/bad-dir')
      File.open('output/good-file.html', 'w') { |io| io.write 'stuff' }
      File.open('output/good-dir/blah', 'w')  { |io| io.write 'stuff' }
      File.open('output/bad-file.html', 'w')  { |io| io.write 'stuff' }
      File.open('output/bad-dir/blah', 'w')   { |io| io.write 'stuff' }
      File.open('output/index.html', 'w')     { |io| io.write 'stuff' }

      Nanoc::CLI.run %w[prune --yes]

      assert File.file?('output/index.html')
      assert File.file?('output/good-dir/blah')
      assert File.file?('output/good-file.html')
      assert !File.file?('output/bad-dir/blah')
      assert !File.file?('output/bad-file.html')
    end
  end

  def test_run_with_symlink_to_output_dir
    skip_unless_symlinks_supported
    if defined?(JRUBY_VERSION)
      skip 'JRuby has buggy File.find behavior (see https://github.com/jruby/jruby/issues/1647)'
    end

    with_site do |_site|
      # Set output dir
      FileUtils.rm_rf('output')
      FileUtils.mkdir_p('output-real')
      File.symlink('output-real', 'output')

      # Create source files
      File.open('content/index.html', 'w') { |io| io.write 'stuff' }

      # Create output files
      FileUtils.mkdir_p('output-real/some-dir')
      File.open('output-real/some-file.html', 'w') { |io| io.write 'stuff' }
      File.open('output-real/index.html', 'w')     { |io| io.write 'stuff' }

      Nanoc::CLI.run %w[prune --yes]

      assert File.file?('output-real/index.html')
      assert !File.directory?('output-real/some-dir')
      assert !File.file?('output-real/some-file.html')
    end
  end

  def test_run_with_nested_empty_dirs
    with_site do |_site|
      # Set output dir
      File.open('nanoc.yaml', 'w') { |io| io.write 'output_dir: output' }
      FileUtils.mkdir_p('output')

      # Create output files
      FileUtils.mkdir_p('output/a/b/c')
      File.open('output/a/b/c/index.html', 'w') { |io| io.write 'stuff' }

      Nanoc::CLI.run %w[prune --yes]

      assert !File.file?('output/a/b/c/index.html')
      assert !File.directory?('output/a/b/c')
      assert !File.directory?('output/a/b')
      assert !File.directory?('output/a')
    end
  end
end
