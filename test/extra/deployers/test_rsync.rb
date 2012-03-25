# encoding: utf-8

class Nanoc::Extra::Deployers::RsyncTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run_without_dst
    if_have 'systemu' do
      # Create deployer
      rsync = Nanoc::Extra::Deployers::Rsync.new(
        'output/',
        {})

      # Mock run_shell_cmd
      def rsync.run_shell_cmd(args)
        @shell_cms_args = args
      end

      # Try running
      error = assert_raises(RuntimeError) do
        rsync.run
      end

      # Check error message
      assert_equal 'No dst found in deployment configuration', error.message
    end
  end

  def test_run_with_erroneous_dst
    if_have 'systemu' do
      # Create deployer
      rsync = Nanoc::Extra::Deployers::Rsync.new(
        'output/',
        { :dst => 'asdf/' })

      # Mock run_shell_cmd
      def rsync.run_shell_cmd(args)
        @shell_cms_args = args
      end

      # Try running
      error = assert_raises(RuntimeError) do
        rsync.run
      end

      # Check error message
      assert_equal 'dst requires no trailing slash', error.message
    end
  end

  def test_run_everything_okay
    if_have 'systemu' do
      # Create deployer
      rsync = Nanoc::Extra::Deployers::Rsync.new(
        'output',
        { :dst => 'asdf' })

      # Mock run_shell_cmd
      def rsync.run_shell_cmd(args)
        @shell_cms_args = args
      end

      # Run
      rsync.run

      # Check args
      opts = Nanoc::Extra::Deployers::Rsync::DEFAULT_OPTIONS
      assert_equal(
        [ 'rsync', opts, 'output/', 'asdf' ].flatten,
        rsync.instance_eval { @shell_cms_args }
      )
    end
  end

  def test_run_everything_okay_dry
    if_have 'systemu' do
      # Create deployer
      rsync = Nanoc::Extra::Deployers::Rsync.new(
        'output',
        { :dst => 'asdf' },
        :dry_run => true)

      # Mock run_shell_cmd
      def rsync.run_shell_cmd(args)
        @shell_cms_args = args
      end

      # Run
      rsync.run

      # Check args
      opts = Nanoc::Extra::Deployers::Rsync::DEFAULT_OPTIONS
      assert_equal(
        [ 'echo', 'rsync', opts, 'output/', 'asdf' ].flatten,
        rsync.instance_eval { @shell_cms_args }
      )
    end
  end

end
