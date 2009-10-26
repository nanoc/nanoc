# encoding: utf-8

module Nanoc3::Extra::Deployers

  # Nanoc3::Extra::Deployers::Rsync is a deployer that deploys a site using rsync.
  class Rsync

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
    #     deploy:
    #       <name>:
    #         options: [ <options> ]
    #         dst:     "<dst>"
    #
    # +<name>+ is a unique name for the deployment configuration. By default,
    # the deployer will use the deployment configuration named "default".
    #
    # +<options>+ is an array containing options to pass to the rsync
    # executable. This is optiona; by default, +-glpPrtvz+ and +--exclude+s
    # for +.svn+, +.hg+ and +.git+ are used.
    #
    # +<dst>+ is a string containing the destination to where rsync should
    # upload its data. It will likely be in +<host>:<path>+ format. For
    # example, "example.com:/var/www/sites/mysite/html". It should not end
    # with a trailing slash.
    #
    # Example: This deployment configuration defines a "default" and a
    # "staging" deployment configuration. The default options are used.
    #
    # deploy:
    #   default:
    #     dst: "ectype:sites/stoneship/public"
    #   staging:
    #     dst: "ectype:sites/stoneship-staging/public"
    def initialize
      # Get site
      error 'No site configuration found' unless File.file?('config.yaml')
      @site = Nanoc3::Site.new('.')
    end

    # Runs the task. Possible params:
    #
    # +:dry_run+:: Set to true when the action itself should not be executed,
    #              but still printed. Useful for debugging.
    #
    # +:config_name+:: The name of the deployment configuration to use.
    #                  Defaults to +:default+ (surprise!).
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
    end

  end

end
