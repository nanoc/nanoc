# encoding: utf-8
require 'lib/nanoc/extra/deployers/git.rb'

class Nanoc::Extra::Deployers::GitTest < Nanoc::TestCase

  def test_run_without_output_folder
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      {})

    # Try running
    error = assert_raises(RuntimeError) do
      git.run
    end

    # Check error message
    assert_equal 'output/ does not exist. Please build your site first.', error.message
  end

  def test_run_with_defaults_options
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      {})

    # Mock run_shell_cmd
    def git.run_shell_cmd(args, opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create site
    FileUtils.mkdir_p('output')

    # Try running
    git.run

    commands = <<-EOS
git init
git config --get remote.origin.url
git checkout master
git add -A
git commit -am Automated commit at .+ by nanoc \\d+\\.\\d+\\.\\d+
git push origin master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_clean_repository
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      {})

    # Mock run_shell_cmd
    def git.run_shell_cmd(args, opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      true
    end

    # Create site
    FileUtils.mkdir_p('output')

    # Try running
    git.run

    commands = <<-EOS
git init
git config --get remote.origin.url
git checkout master
git push origin master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_custom_options
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      { :remote => 'github', :branch => 'gh-pages', :forced => true })

    # Mock run_shell_cmd
    def git.run_shell_cmd(args, opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create site
    FileUtils.mkdir_p('output')

    # Try running
    git.run

    commands = <<-EOS
git init
git config --get remote.github.url
git checkout gh-pages
git add -A
git commit -am Automated commit at .+ by nanoc \\d+\\.\\d+\\.\\d+
git push -f github gh-pages
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_without_git_init
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      {})

    # Mock run_shell_cmd
    def git.run_shell_cmd(args, opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create site
    FileUtils.mkdir_p('output/.git')

    # Try running
    git.run

    commands = <<-EOS
git config --get remote.origin.url
git checkout master
git add -A
git commit -am Automated commit at .+ by nanoc \\d+\\.\\d+\\.\\d+
git push origin master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_ssh_url
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      { :remote => 'git@github.com:myself/myproject.git' })

    # Mock run_shell_cmd
    def git.run_shell_cmd(args, opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create site
    FileUtils.mkdir_p('output')

    # Try running
    git.run

    commands = <<-EOS
git init
git checkout master
git add -A
git commit -am Automated commit at .+ by nanoc \\d+\\.\\d+\\.\\d+
git push git@github.com:myself/myproject.git master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_http_url
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      { :remote => 'https://github.com/nanoc/nanoc.git' })

    # Mock run_shell_cmd
    def git.run_shell_cmd(args, opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create site
    FileUtils.mkdir_p('output')

    # Try running
    git.run

    commands = <<-EOS
git init
git checkout master
git add -A
git commit -am Automated commit at .+ by nanoc \\d+\\.\\d+\\.\\d+
git push https://github.com/nanoc/nanoc.git master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_clean_repo_on_a_clean_repo
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      { :remote => 'https://github.com/nanoc/nanoc.git' })

    FileUtils.mkdir_p('output')

    piper = Nanoc::Extra::Piper.new(:stdout => $stdout, :stderr => $stderr)

    Dir.chdir('output') do
      piper.run('git init', nil)
      assert git.send(:clean_repo?)
    end
  end

  def test_clean_repo_on_a_dirty_repo
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      { :remote => 'https://github.com/nanoc/nanoc.git' })

    FileUtils.mkdir_p('output')

    piper = Nanoc::Extra::Piper.new(:stdout => $stdout, :stderr => $stderr)
    Dir.chdir('output') do
      piper.run('git init', nil)
      FileUtils.touch('foobar')
      refute git.send(:clean_repo?)
    end
  end

  def test_clean_repo_not_git_repo
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      { :remote => 'https://github.com/nanoc/nanoc.git' })

    FileUtils.mkdir_p('output')

    Dir.chdir('output') do
      assert_raises Nanoc::Extra::Piper::Error do
        git.send(:clean_repo?)
      end
    end
  end
end
