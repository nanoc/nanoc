# frozen_string_literal: true

require 'helper'

class Nanoc::OrigCLITest < Nanoc::TestCase
  COMMAND_CODE = <<~EOS
    usage       '_test [options]'
    summary     'meh'
    description 'longer meh'

    run do |opts, args, cmd|
      File.open('_test.out', 'w') { |io| io.write('It works!') }
    end
  EOS

  SUBCOMMAND_CODE = <<~EOS
    usage       '_sub [options]'
    summary     'meh sub'
    description 'longer meh sub'

    run do |opts, args, cmd|
      File.open('_test_sub.out', 'w') { |io| io.write('It works sub!') }
    end
  EOS

  def test_load_custom_commands
    Nanoc::CLI.run %w[create_site foo]

    FileUtils.cd('foo') do
      # Create command
      FileUtils.mkdir_p('commands')
      File.write('commands/_test.rb', COMMAND_CODE)

      # Run command
      begin
        Nanoc::CLI.run %w[_test]
      rescue SystemExit
        assert false, 'Running _test should not cause system exit'
      end

      # Check
      assert File.file?('_test.out')
      assert_equal 'It works!', File.read('_test.out')
    end
  end

  def test_load_custom_commands_nested
    Nanoc::CLI.run %w[create_site foo]
    FileUtils.cd('foo') do
      # Create command
      FileUtils.mkdir_p('commands')
      File.write('commands/_test.rb', COMMAND_CODE)

      # Create subcommand
      FileUtils.mkdir_p('commands/_test')
      File.write('commands/_test/_sub.rb', SUBCOMMAND_CODE)

      # Run command
      begin
        Nanoc::CLI.run %w[_test _sub]
      rescue SystemExit
        assert false, 'Running _test sub should not cause system exit'
      end

      # Check
      assert File.file?('_test_sub.out')
      assert_equal 'It works sub!', File.read('_test_sub.out')
    end
  end

  def test_load_custom_commands_non_default_commands_dirs
    Nanoc::CLI.run %w[create_site foo]
    FileUtils.cd('foo') do
      File.write('nanoc.yaml', 'commands_dirs: [commands, commands_alt]')

      # Create command
      FileUtils.mkdir_p('commands_alt')
      File.write('commands_alt/_test.rb', COMMAND_CODE)

      # Create subcommand
      FileUtils.mkdir_p('commands_alt/_test')
      File.write('commands_alt/_test/_sub.rb', SUBCOMMAND_CODE)

      # Run command
      begin
        Nanoc::CLI.run %w[_test _sub]
      rescue SystemExit
        assert false, 'Running _test sub should not cause system exit'
      end

      # Check
      assert File.file?('_test_sub.out')
      assert_equal 'It works sub!', File.read('_test_sub.out')
    end
  end

  def test_load_custom_commands_broken
    Nanoc::CLI.run %w[create_site foo]

    FileUtils.cd('foo') do
      # Create command
      FileUtils.mkdir_p('commands')
      File.write('commands/_test.rb', 'raise "meh"')

      begin
        orig_stderr = $stderr
        tmp_stderr = StringIO.new
        $stderr = tmp_stderr

        # Run command
        Nanoc::CLI::ErrorHandler.disable
        assert_raises RuntimeError do
          Nanoc::CLI.run %w[_test]
        end
        Nanoc::CLI::ErrorHandler.enable
        assert_raises SystemExit do
          Nanoc::CLI.run %w[_test]
        end
      ensure
        $stderr = orig_stderr
      end

      # Check error output
      assert_match(/commands\/_test.rb/, tmp_stderr.string)
    end
  end

  def test_after_setup
    $after_setup_success = false
    Nanoc::CLI.after_setup do
      $after_setup_success = true
    end
    Nanoc::CLI.setup

    assert $after_setup_success
  end
end
