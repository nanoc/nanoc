# encoding: utf-8

class Nanoc::CLITest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  COMMAND_CODE = <<EOS
# encoding: utf-8

usage       '_test [options]'
summary     'meh'
description 'longer meh'

run do |opts, args, cmd|
  File.open('_test.out', 'w') { |io| io.write('It works!') }
end
EOS

  SUBCOMMAND_CODE = <<EOS
# encoding: utf-8

usage       '_sub [options]'
summary     'meh sub'
description 'longer meh sub'

run do |opts, args, cmd|
  File.open('_test_sub.out', 'w') { |io| io.write('It works sub!') }
end
EOS

  def test_load_custom_commands
    Nanoc::CLI.run %w( create_site foo )

    FileUtils.cd('foo') do
      # Create command
      FileUtils.mkdir_p('commands')
      File.open('commands/_test.rb', 'w') { |io| io.write(COMMAND_CODE) }

      # Run command
      begin
        Nanoc::CLI.run %w( _test )
      rescue SystemExit
        assert false, 'Running _test should not cause system exit'
      end

      # Check
      assert File.file?('_test.out')
      assert_equal 'It works!', File.read('_test.out')
    end
  end

  def test_load_custom_commands_nested
    Nanoc::CLI.run %w( create_site foo )
    FileUtils.cd('foo') do
      # Create command
      FileUtils.mkdir_p('commands')
      File.open('commands/_test.rb', 'w') do |io|
        io.write(COMMAND_CODE)
      end

      # Create subcommand
      FileUtils.mkdir_p('commands/_test')
      File.open('commands/_test/_sub.rb', 'w') do |io|
        io.write(SUBCOMMAND_CODE)
      end

      # Run command
      begin
        Nanoc::CLI.run %w( _test _sub )
      rescue SystemExit
        assert false, 'Running _test sub should not cause system exit'
      end

      # Check
      assert File.file?('_test_sub.out')
      assert_equal 'It works sub!', File.read('_test_sub.out')
    end
  end

  def test_load_custom_commands_broken
    Nanoc::CLI.run %w( create_site foo )

    FileUtils.cd('foo') do
      # Create command
      FileUtils.mkdir_p('commands')
      File.open('commands/_test.rb', 'w') { |io| io.write('raise "meh"') }

      # Run command
      position_before = $stderr.tell
      Nanoc::CLI::ErrorHandler.disable
      assert_raises RuntimeError do
        Nanoc::CLI.run %w( _test )
      end
      Nanoc::CLI::ErrorHandler.enable
      assert_raises SystemExit do
        Nanoc::CLI.run %w( _test )
      end
      position_after = $stderr.tell

      # Check error output
      stderr_addition = $stderr.string[position_before, position_after]
      assert_match(/Stack trace:/, stderr_addition)
      assert_match(/commands\/_test.rb/, stderr_addition)
    end
  end

end
