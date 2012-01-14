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

end
