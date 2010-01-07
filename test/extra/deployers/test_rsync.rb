# encoding: utf-8

require 'test/helper'

class Nanoc3::Extra::Deployers::RsyncTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_new_without_site
    # Try creating site
    error = assert_raises(RuntimeError) do
      Nanoc3::Extra::Deployers::Rsync.new
    end

    # Check error message
    assert_equal 'No site configuration found', error.message
  end

  def test_run_without_general_deploy_config
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "foo: bar\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Try running
    error = assert_raises(RuntimeError) do
      rsync.run
    end

    # Check error message
    assert_equal 'No deploy configuration found', error.message
  end

  def test_run_without_special_deploy_config
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "deploy:\n"
      io.write "  blahblah:\n"
      io.write "    stuff: more stuff\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Try running
    error = assert_raises(RuntimeError) do
      rsync.run
    end

    # Check error message
    assert_equal 'No deploy configuration found for default', error.message
  end

  def test_run_without_special_deploy_config_with_custom_deploy_config
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "deploy:\n"
      io.write "  blahblah:\n"
      io.write "    stuff: more stuff\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Try running
    error = assert_raises(RuntimeError) do
      rsync.run(:config_name => 'potrzebie')
    end

    # Check error message
    assert_equal 'No deploy configuration found for potrzebie', error.message
  end

  def test_run_without_dst
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "deploy:\n"
      io.write "  default:\n"
      io.write "    foo: bar\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Try running
    error = assert_raises(RuntimeError) do
      rsync.run
    end

    # Check error message
    assert_equal 'No dst found in deployment configuration', error.message
  end

  def test_run_with_erroneous_dst
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "deploy:\n"
      io.write "  default:\n"
      io.write "    dst: asdf/\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Try running
    error = assert_raises(RuntimeError) do
      rsync.run
    end

    # Check error message
    assert_equal 'dst requires no trailing slash', error.message
  end

  def test_run_with_custom_deploy_config_string
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "deploy:\n"
      io.write "  foobar:\n"
      io.write "    dst: asdf\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Mock run_shell_cmd
    def rsync.run_shell_cmd(args)
      @shell_cms_args = args
    end

    # Run
    rsync.run(:config_name => 'foobar')

    # Check args
    default_options = Nanoc3::Extra::Deployers::Rsync::DEFAULT_OPTIONS
    assert_equal(
      [ 'rsync', default_options, File.expand_path('output') + '/', 'asdf' ].flatten,
      rsync.instance_eval { @shell_cms_args }
    )
  end

  def test_run_with_custom_deploy_config_symbol
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "deploy:\n"
      io.write "  foobar:\n"
      io.write "    dst: asdf\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Mock run_shell_cmd
    def rsync.run_shell_cmd(args)
      @shell_cms_args = args
    end

    # Run
    rsync.run(:config_name => :foobar)

    # Check args
    default_options = Nanoc3::Extra::Deployers::Rsync::DEFAULT_OPTIONS
    assert_equal(
      [ 'rsync', default_options, File.expand_path('output') + '/', 'asdf' ].flatten,
      rsync.instance_eval { @shell_cms_args }
    )
  end

  def test_run_everything_okay
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "deploy:\n"
      io.write "  default:\n"
      io.write "    dst: asdf\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Mock run_shell_cmd
    def rsync.run_shell_cmd(args)
      @shell_cms_args = args
    end

    # Run
    rsync.run

    # Check args
    default_options = Nanoc3::Extra::Deployers::Rsync::DEFAULT_OPTIONS
    assert_equal(
      [ 'rsync', default_options, File.expand_path('output') + '/', 'asdf' ].flatten,
      rsync.instance_eval { @shell_cms_args }
    )
  end

  def test_run_everything_okay_dry
    # Create config
    File.open('config.yaml', 'w') do |io|
      io.write "---\n"
      io.write "deploy:\n"
      io.write "  default:\n"
      io.write "    dst: asdf\n"
    end

    # Create site
    rsync = Nanoc3::Extra::Deployers::Rsync.new

    # Mock run_shell_cmd
    def rsync.run_shell_cmd(args)
      @shell_cms_args = args
    end

    # Run
    rsync.run(:dry_run => true)

    # Check args
    default_options = Nanoc3::Extra::Deployers::Rsync::DEFAULT_OPTIONS
    assert_equal(
      [ 'echo', 'rsync', default_options, File.expand_path('output') + '/', 'asdf' ].flatten,
      rsync.instance_eval { @shell_cms_args }
    )
  end

end
