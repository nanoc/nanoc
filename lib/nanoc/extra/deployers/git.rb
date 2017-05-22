# encoding: utf-8

module Nanoc::Extra::Deployers
  # A deployer that deploys a site using [Git](http://git-scm.com).
  #
  # @example A deployment configuration for GitHub Pages:
  #
  #   deploy:
  #     default:
  #       kind:       git
  #       remote:     git@github.com:myself/myproject.git
  #       branch:     gh-pages
  #       forced:     true
  #
  class Git < ::Nanoc::Extra::Deployer
    identifier :git

    # @see Nanoc::Extra::Deployer#run
    def run
      unless File.exist?(source_path)
        raise "#{source_path} does not exist. Please build your site first."
      end

      remote = config.fetch(:remote, 'origin')
      branch = config.fetch(:branch, 'master')
      forced = config.fetch(:forced, false)

      puts "Deploying via git to remote='#{remote}' and branch='#{branch}'"

      Dir.chdir(source_path) do
        unless File.exist?('.git')
          puts "#{source_path} does not appear to be a Git repo. Creating one..."
          run_shell_cmd(%w( git init ))
        end

        # If the remote is not a URL already, verify that it is defined.
        # Examples of URLs:
        #    https://github.com/nanoc/nanoc.git
        #    git@github.com:lifepillar/nanoc.git
        unless remote.match(/:\/\/|@.+:/)
          begin
            run_shell_cmd(%W( git config --get remote.#{remote}.url ))
          rescue Nanoc::Extra::Piper::Error
            raise "Please add a remote called '#{remote}' to the repo inside #{source_path}."
          end
        end

        # If the branch exists then switch to it, otherwise prompt the user to create one.
        begin
          run_shell_cmd(%W( git checkout #{branch} ))
        rescue
          raise "Branch '#{branch}' does not exist inside #{source_path}. Please create one and try again."
        end

        unless clean_repo?
          msg = "Automated commit at #{Time.now.utc} by nanoc #{Nanoc::VERSION}"
          run_shell_cmd(%w( git add -A ))
          run_shell_cmd(%W( git commit -am #{msg} ))
        end
        if forced
          run_shell_cmd(%W( git push -f #{remote} #{branch} ))
        else
          run_shell_cmd(%W( git push #{remote} #{branch} ))
        end
      end
    end

    private

    def run_shell_cmd(cmd)
      if dry_run
        puts cmd.join(' ')
      else
        piper = Nanoc::Extra::Piper.new(:stdout => $stdout, :stderr => $stderr)
        piper.run(cmd, nil)
      end
    end

    def clean_repo?
      if dry_run && !File.exist?('.git')
        true
      else
        stdout = StringIO.new
        piper = Nanoc::Extra::Piper.new(:stdout => stdout, :stderr => $stderr)
        piper.run(%w( git status --porcelain ), nil)
        stdout.string.empty?
      end
    end
  end
end
