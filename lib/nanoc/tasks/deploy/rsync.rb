module Nanoc::Tasks::Deploy # :nodoc:

  # Nanoc::Tasks::Deploy::Rsync is a task that deploys a site using rsync.
  class Rsync

    # Creates a new deployment task that uses rsync. The deployment
    # configuration will be taken from the site's configuration file.
    def initialize
      # Get site
      error 'No site configuration found' unless File.file?('config.yaml')
      @site = Nanoc::Site.new(YAML.load_file('config.yaml'))
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
      config_name = params.has_key?(:config_name) ? params[:config_name] : :default
      dry_run     = params.has_key?(:dry_run)     ? params[:dry_run]     : false

      # Validate config
      error 'No deploy configuration found'                    if @site.config[:deploy].nil?
      error "No deploy configuration found for #{config_name}" if @site.config[:deploy][config_name].nil?

      # Set arguments
      src = File.expand_path(@site.config[:output_dir]) + '/'
      dst = @site.config[:deploy][config_name][:dst]
      options = @site.config[:deploy][config_name][:options] || []

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
