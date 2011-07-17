# encoding: utf-8

class Nanoc::CLI::Commands::DeployTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_deploy
    with_site do |site|
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  public:\n"
        io.write "    kind: rsync\n"
        io.write "    dst: mydestination"
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      Nanoc::CLI.run %w( deploy -t public )

      assert File.directory?('mydestination')
      assert File.file?('mydestination/blah.html')
    end
  end

  def test_deploy_with_dry_run
    with_site do |site|
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  public:\n"
        io.write "    kind: rsync\n"
        io.write "    dst: mydestination"
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      Nanoc::CLI.run %w( deploy -t public -n )

      refute File.directory?('mydestination')
      refute File.file?('mydestination/blah.html')
    end
  end

end
