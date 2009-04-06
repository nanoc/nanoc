require 'test/helper'

class Nanoc3::Tasks::Deploy::RsyncTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_new_without_site
    # Try creating site
    error = assert_raises(RuntimeError) do
      Nanoc3::Tasks::Deploy::Rsync.new
    end

    # Check error message
    assert_equal 'No site configuration found', error.message
  end

  def test_run_without_general_deploy_config
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "foo: bar\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Try running
      error = assert_raises(RuntimeError) do
        rsync.run
      end

      # Check error message
      assert_equal 'No deploy configuration found', error.message
    end
  end

  def test_run_without_special_deploy_config
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  blahblah:\n"
        io.write "    stuff: more stuff\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Try running
      error = assert_raises(RuntimeError) do
        rsync.run
      end

      # Check error message
      assert_equal 'No deploy configuration found for default', error.message
    end
  end

  def test_run_without_special_deploy_config_with_custom_deploy_config
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  blahblah:\n"
        io.write "    stuff: more stuff\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Try running
      error = assert_raises(RuntimeError) do
        rsync.run(:config_name => 'potrzebie')
      end

      # Check error message
      assert_equal 'No deploy configuration found for potrzebie', error.message
    end
  end

  def test_run_without_dst
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  default:\n"
        io.write "    foo: bar\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Try running
      error = assert_raises(RuntimeError) do
        rsync.run
      end

      # Check error message
      assert_equal 'No dst found in deployment configuration', error.message
    end
  end

  def test_run_with_erroneous_dst
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  default:\n"
        io.write "    dst: asdf/\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Try running
      error = assert_raises(RuntimeError) do
        rsync.run
      end

      # Check error message
      assert_equal 'dst requires no trailing slash', error.message
    end
  end

  def test_run_with_custom_deploy_config_string
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  foobar:\n"
        io.write "    dst: asdf\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Mock run_shell_cmd
      def rsync.run_shell_cmd(args)
        @shell_cms_args = args
      end

      # Run
      rsync.run(:config_name => 'foobar')

      # Check args
      assert_equal(
        [ 'rsync', File.expand_path('output') + '/', 'asdf' ],
        rsync.instance_eval { @shell_cms_args }
      )
    end
  end

  def test_run_with_custom_deploy_config_symbol
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  foobar:\n"
        io.write "    dst: asdf\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Mock run_shell_cmd
      def rsync.run_shell_cmd(args)
        @shell_cms_args = args
      end

      # Run
      rsync.run(:config_name => :foobar)

      # Check args
      assert_equal(
        [ 'rsync', File.expand_path('output') + '/', 'asdf' ],
        rsync.instance_eval { @shell_cms_args }
      )
    end
  end

  def test_run_everything_okay
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  default:\n"
        io.write "    dst: asdf\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Mock run_shell_cmd
      def rsync.run_shell_cmd(args)
        @shell_cms_args = args
      end

      # Run
      rsync.run

      # Check args
      assert_equal(
        [ 'rsync', File.expand_path('output') + '/', 'asdf' ],
        rsync.instance_eval { @shell_cms_args }
      )
    end
  end

  def test_run_everything_okay_dry
    in_dir 'tmp' do
      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  default:\n"
        io.write "    dst: asdf\n"
      end

      # Create site
      rsync = Nanoc3::Tasks::Deploy::Rsync.new

      # Mock run_shell_cmd
      def rsync.run_shell_cmd(args)
        @shell_cms_args = args
      end

      # Run
      rsync.run(:dry_run => true)

      # Check args
      assert_equal(
        [ 'echo', 'rsync', File.expand_path('output') + '/', 'asdf' ],
        rsync.instance_eval { @shell_cms_args }
      )
    end
  end

end
