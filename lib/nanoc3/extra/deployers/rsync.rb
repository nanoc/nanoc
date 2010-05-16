# encoding: utf-8

module Nanoc3::Extra::Deployers

  # A deployer that deploys a site using rsync.
  class Rsync

    # Default rsync options
    DEFAULT_OPTIONS = [
      '-glpPrtvz',
      '--exclude=".hg"',
      '--exclude=".svn"',
      '--exclude=".git"'
    ]

    # Creates a new deployer that uses rsync. The deployment configurations
    # will be read from the configuration file of the site (which is assumed
    # to be the current working directory).
    #
    # The deployment configurations are stored like this in the site's
    # configuration file:
    #
    #   deploy:
    #     NAME:
    #       options: [ OPTIONS ]
    #       dst:     "DST"
    #
    # `NAME` is a unique name for the deployment configuration. By default,
    # the deployer will use the deployment configuration named `"default"`.
    #
    # `OPTIONS` is an array containing options to pass to the rsync
    # executable. This is not required; by default, {DEFAULT_OPTIONS} options
    # will be used.
    #
    # `DST` is a string containing the destination to where rsync should
    # upload its data. It will likely be in `host:path` format. For example,
    # `"example.com:/var/www/sites/mysite/html"`. It should not end with a
    # trailing slash.
    #
    # Example: This deployment configuration defines a "default" and a
    # "staging" deployment configuration. The default options are used.
    #
    #   deploy:
    #     default:
    #       dst: "ectype:sites/stoneship/public"
    #     staging:
    #       dst: "ectype:sites/stoneship-staging/public"
    #       options: [ "-glpPrtvz" ]
    #
    # When running the deployer with the `default` resp. `staging`
    # configurations, the following rsync commands will be executed:
    #
    #   rsync -glpPrtvz --exclude=".hg" --exclude=".svn"
    #     --exclude=".git" output ectype:sites/stoneship/public
    #
    #   rsync -glpPrtvz output ectype:sites/stoneship-staging/public
    def initialize
      # Get site
      error 'No site configuration found' unless File.file?('config.yaml')
      @site = Nanoc3::Site.new('.')
    end

    # Runs the task. Possible params:
    #
    # @option params [Boolean] :dry_run (false) True if the action itself
    # should not be executed, but still printed; false otherwise.
    #
    # @option params [String] :config_name (:default) The name of the
    # deployment configuration to use.
    #
    # @return [void]
    def run(params={})
      # Extract params
      config_name = params.has_key?(:config_name) ? params[:config_name].to_sym : :default
      dry_run     = params.has_key?(:dry_run)     ? params[:dry_run]            : false

      # Validate config
      error 'No deploy configuration found'                    if @site.config[:deploy].nil?
      error "No deploy configuration found for #{config_name}" if @site.config[:deploy][config_name].nil?

      # Set arguments
      src = File.expand_path(@site.config[:output_dir]) + '/'
      dst = @site.config[:deploy][config_name][:dst]
      options = @site.config[:deploy][config_name][:options] || DEFAULT_OPTIONS

      # Validate arguments
      error 'No dst found in deployment configuration' if dst.nil?
      error 'dst requires no trailing slash' if dst[-1,1] == '/'

      # Run
      if dry_run
        warn 'Performing a dry-run; no actions will actually be performed'
        run_shell_cmd([ 'echo', 'rsync', options, src, dst ].flatten)
      else
        run_shell_cmd([ 'rsync', options, src, dst ].flatten)
      end
    end

  private

    # Prints the given message on stderr and exits.
    def error(msg)
      raise RuntimeError.new(msg)
    end

    # Runs the given shell command. This is a simple wrapper around Kernel#system.
    def run_shell_cmd(args)
      system(*args)
      raise "command exited with a nonzero status code #{$?.exitstatus} (command: #{args.join(' ')})" if !$?.success?
    end

  end

end
