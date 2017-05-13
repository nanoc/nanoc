# frozen_string_literal: true

class Nanoc::Deploying::Deployers::GitTest < Nanoc::TestCase
  def test_run_with_defaults_options
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      {}
    )

    # Mock run_cmd
    def git.run_cmd(args, _opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create output dir + repo
    FileUtils.mkdir_p('output')
    Dir.chdir('output') { system('git', 'init', '--quiet') }

    # Try running
    git.run

    commands = <<~EOS
      git config --get remote.origin.url
      git checkout master
      git add -A
      git commit -a --author Nanoc <> -m Automated commit at .+ by Nanoc \\d+\\.\\d+\\.\\d+\\w*
      git push origin master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_clean_repository
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      {}
    )

    # Mock run_cmd
    def git.run_cmd(args, _opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      true
    end

    # Create output dir + repo
    FileUtils.mkdir_p('output')
    Dir.chdir('output') { system('git', 'init', '--quiet') }

    # Try running
    git.run

    commands = <<~EOS
      git config --get remote.origin.url
      git checkout master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_custom_options
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      remote: 'github', branch: 'gh-pages', forced: true,
    )

    # Mock run_cmd
    def git.run_cmd(args, _opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create output dir + repo
    FileUtils.mkdir_p('output')
    Dir.chdir('output') { system('git', 'init', '--quiet') }

    # Try running
    git.run

    commands = <<~EOS
      git config --get remote.github.url
      git checkout gh-pages
      git add -A
      git commit -a --author Nanoc <> -m Automated commit at .+ by Nanoc \\d+\\.\\d+\\.\\d+\\w*
      git push -f github gh-pages
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_without_git_init
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      {}
    )

    # Mock run_cmd
    def git.run_cmd(args, _opts = {})
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

    commands = <<~EOS
      git config --get remote.origin.url
      git checkout master
      git add -A
      git commit -a --author Nanoc <> -m Automated commit at .+ by Nanoc \\d+\\.\\d+\\.\\d+\\w*
      git push origin master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_ssh_url
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      remote: 'git@github.com:myself/myproject.git',
    )

    # Mock run_cmd
    def git.run_cmd(args, _opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create output dir + repo
    FileUtils.mkdir_p('output')
    Dir.chdir('output') { system('git', 'init', '--quiet') }

    # Try running
    git.run

    commands = <<~EOS
      git checkout master
      git add -A
      git commit -a --author Nanoc <> -m Automated commit at .+ by Nanoc \\d+\\.\\d+\\.\\d+\\w*
      git push git@github.com:myself/myproject.git master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_http_url
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      remote: 'https://github.com/nanoc/nanoc.git',
    )

    # Mock run_cmd
    def git.run_cmd(args, _opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Mock clean_repo?
    def git.clean_repo?
      false
    end

    # Create output dir + repo
    FileUtils.mkdir_p('output')
    Dir.chdir('output') { system('git', 'init', '--quiet') }

    # Try running
    git.run

    commands = <<~EOS
      git checkout master
      git add -A
      git commit -a --author Nanoc <> -m Automated commit at .+ by Nanoc \\d+\\.\\d+\\.\\d+\\w*
      git push https://github.com/nanoc/nanoc.git master
EOS

    assert_match Regexp.new(/^#{commands.chomp}$/), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_clean_repo_on_a_clean_repo
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      remote: 'https://github.com/nanoc/nanoc.git',
    )

    FileUtils.mkdir_p('output')

    piper = Nanoc::Extra::Piper.new(stdout: $stdout, stderr: $stderr)

    Dir.chdir('output') do
      piper.run('git init', nil)
      assert git.send(:clean_repo?)
    end
  end

  def test_clean_repo_on_a_dirty_repo
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      remote: 'https://github.com/nanoc/nanoc.git',
    )

    FileUtils.mkdir_p('output')

    piper = Nanoc::Extra::Piper.new(stdout: $stdout, stderr: $stderr)
    Dir.chdir('output') do
      piper.run('git init', nil)
      FileUtils.touch('foobar')
      refute git.send(:clean_repo?)
    end
  end

  def test_clean_repo_not_git_repo
    # Create deployer
    git = Nanoc::Deploying::Deployers::Git.new(
      'output/',
      remote: 'https://github.com/nanoc/nanoc.git',
    )

    FileUtils.mkdir_p('output')

    Dir.chdir('output') do
      assert_raises Nanoc::Extra::Piper::Error do
        git.send(:clean_repo?)
      end
    end
  end
end
