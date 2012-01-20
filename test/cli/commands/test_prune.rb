# encoding: utf-8

class Nanoc::CLI::Commands::PruneTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run_without_yes
    with_site do |site|
      # Set output dir
      File.open('config.yaml', 'w') { |io| io.write 'output_dir: output2' }
      FileUtils.mkdir_p('output2')

      # Create source files
      File.open('content/index.html', 'w') { |io| io.write 'stuff' }

      # Create output files
      File.open('output2/foo.html', 'w')   { |io| io.write 'this is a foo.' }
      File.open('output2/index.html', 'w') { |io| io.write 'this is a index.' }

      assert_raises SystemExit do
        Nanoc::CLI.run %w( prune )
      end

      assert File.file?('output2/index.html')
      assert File.file?('output2/foo.html')
    end
  end

  def test_run_with_yes
    with_site do |site|
      # Set output dir
      File.open('config.yaml', 'w') { |io| io.write 'output_dir: output2' }
      FileUtils.mkdir_p('output2')

      # Create source files
      File.open('content/index.html', 'w') { |io| io.write 'stuff' }

      # Create output files
      File.open('output2/foo.html', 'w')   { |io| io.write 'this is a foo.' }
      File.open('output2/index.html', 'w') { |io| io.write 'this is a index.' }

      Nanoc::CLI.run %w( prune --yes )

      assert File.file?('output2/index.html')
      assert !File.file?('output2/foo.html')
    end
  end

  def test_run_with_dry_run
    with_site do |site|
      # Set output dir
      File.open('config.yaml', 'w') { |io| io.write 'output_dir: output2' }
      FileUtils.mkdir_p('output2')

      # Create source files
      File.open('content/index.html', 'w') { |io| io.write 'stuff' }

      # Create output files
      File.open('output2/foo.html', 'w')   { |io| io.write 'this is a foo.' }
      File.open('output2/index.html', 'w') { |io| io.write 'this is a index.' }

      Nanoc::CLI.run %w( prune --dry-run )

      assert File.file?('output2/index.html')
      assert File.file?('output2/foo.html')
    end
  end

  def test_run_with_exclude
     with_site do |site|
      # Set output dir
      File.open('config.yaml', 'w') { |io| io.write "prune:\n  exclude: [ 'good-dir', 'good-file.html' ]" }
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

      Nanoc::CLI.run %w( prune --yes )

      assert File.file?('output/index.html')
      assert File.file?('output/good-dir/blah')
      assert File.file?('output/good-file.html')
      assert !File.file?('output/bad-dir/blah')
      assert !File.file?('output/bad-file.html')
    end
  end

end

