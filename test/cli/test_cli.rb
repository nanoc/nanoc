# frozen_string_literal: true

require 'helper'

class Nanoc::CLITest < Nanoc::TestCase
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
      File.open('commands/_test.rb', 'w') { |io| io.write(COMMAND_CODE) }

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
      File.open('nanoc.yaml', 'w') { |io| io.write('commands_dirs: [commands, commands_alt]') }

      # Create command
      FileUtils.mkdir_p('commands_alt')
      File.open('commands_alt/_test.rb', 'w') do |io|
        io.write(COMMAND_CODE)
      end

      # Create subcommand
      FileUtils.mkdir_p('commands_alt/_test')
      File.open('commands_alt/_test/_sub.rb', 'w') do |io|
        io.write(SUBCOMMAND_CODE)
      end

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
      File.open('commands/_test.rb', 'w') { |io| io.write('raise "meh"') }

      # Run command
      position_before = $stderr.tell
      Nanoc::CLI::ErrorHandler.disable
      assert_raises RuntimeError do
        Nanoc::CLI.run %w[_test]
      end
      Nanoc::CLI::ErrorHandler.enable
      assert_raises SystemExit do
        Nanoc::CLI.run %w[_test]
      end
      position_after = $stderr.tell

      # Check error output
      stderr_addition = $stderr.string[position_before, position_after]
      assert_match(/Stack trace:/, stderr_addition)
      assert_match(/commands\/_test.rb/, stderr_addition)
    end
  end

  def test_load_command_at_with_non_utf8_encoding
    Encoding.default_external = Encoding::US_ASCII
    Nanoc::CLI.load_command_at(root_dir + '/lib/nanoc/cli/commands/create-site.rb')
  ensure
    Encoding.default_external = Encoding::UTF_8
  end

  def test_after_setup
    $after_setup_success = false
    Nanoc::CLI.after_setup do
      $after_setup_success = true
    end
    Nanoc::CLI.setup
    assert $after_setup_success
  end

  def test_enable_utf8_only_on_tty
    new_env_diff = {
      'LC_ALL'   => 'en_US.ISO-8859-1',
      'LC_CTYPE' => 'en_US.ISO-8859-1',
      'LANG'     => 'en_US.ISO-8859-1',
    }
    with_env_vars(new_env_diff) do
      io = StringIO.new
      def io.tty?
        true
      end
      refute Nanoc::CLI.enable_utf8?(io)

      io = StringIO.new
      def io.tty?
        false
      end
      assert Nanoc::CLI.enable_utf8?(io)
    end
  end

  def test_enable_utf8
    io = StringIO.new
    def io.tty?
      true
    end

    new_env_diff = {
      'LC_ALL'   => 'en_US.ISO-8859-1',
      'LC_CTYPE' => 'en_US.ISO-8859-1',
      'LANG'     => 'en_US.ISO-8859-1',
    }
    with_env_vars(new_env_diff) do
      refute Nanoc::CLI.enable_utf8?(io)

      with_env_vars('LC_ALL'   => 'en_US.UTF-8') { assert Nanoc::CLI.enable_utf8?(io) }
      with_env_vars('LC_CTYPE' => 'en_US.UTF-8') { assert Nanoc::CLI.enable_utf8?(io) }
      with_env_vars('LANG'     => 'en_US.UTF-8') { assert Nanoc::CLI.enable_utf8?(io) }

      with_env_vars('LC_ALL'   => 'en_US.utf-8') { assert Nanoc::CLI.enable_utf8?(io) }
      with_env_vars('LC_CTYPE' => 'en_US.utf-8') { assert Nanoc::CLI.enable_utf8?(io) }
      with_env_vars('LANG'     => 'en_US.utf-8') { assert Nanoc::CLI.enable_utf8?(io) }

      with_env_vars('LC_ALL'   => 'en_US.utf8') { assert Nanoc::CLI.enable_utf8?(io) }
      with_env_vars('LC_CTYPE' => 'en_US.utf8') { assert Nanoc::CLI.enable_utf8?(io) }
      with_env_vars('LANG'     => 'en_US.utf8') { assert Nanoc::CLI.enable_utf8?(io) }
    end
  end
end
