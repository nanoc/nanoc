module Nanoc::CLI

  # Nanoc::CLI::Base is the central class representing a commandline nanoc
  # tool. It has a list of commands, and is linked to a specific nanoc site.
  class Base

    attr_reader :commands, :site

    # Creates a new instance of the commandline nanoc tool.
    def initialize
      create_commands
    end

    # Parses the given commandline arguments and executes the requested
    # command.
    def run(args)
      # Check arguments
      if args.length == 0
        @help_command.run([], [])
        exit 1
      end

      # Find version or help options
      if args.length == 1
        # Parse arguments
        begin
          parsed_arguments = Nanoc::CLI::OptionParser.parse(args[0..1], global_option_definitions)
        rescue Nanoc::CLI::OptionParser::IllegalOptionError => e
          $stderr.puts "illegal option -- #{e}"
          exit 1
        end

        # Handle version option
        if parsed_arguments[:options].has_key?(:version)
          puts "nanoc #{Nanoc::VERSION} (c) 2007-2008 Denis Defreyne."
          exit 1
        # Handle help option
        elsif parsed_arguments[:options].has_key?(:help)
          show_help
          exit 1
        end
      end

      # Find command
      command = command_named(args[0])

      # Get extended option definitions (with help)
      extended_option_definitions = command.option_definitions + [
        # --vcs
        {
          :long => 'vcs', :short => 'c', :argument => :required,
          :desc => 'select the VCS to use'
        },
        # --help
        {
          :long => 'help', :short => 'h', :argument => :forbidden,
          :desc => 'show this help message and quit'
        },
        # --verbose
        {
          :long => 'verbose', :short => 'V', :argument => :forbidden,
          :desc => 'enable more detailed output'
        }
      ]

      # Parse arguments
      begin
        parsed_arguments = Nanoc::CLI::OptionParser.parse(args[1..-1], extended_option_definitions)
      rescue Nanoc::CLI::OptionParser::IllegalOptionError => e
        $stderr.puts "illegal option -- #{e}"
        exit 1
      rescue Nanoc::CLI::OptionParser::OptionRequiresAnArgumentError => e
        $stderr.puts "option requires an argument -- #{e}"
        exit 1
      end

      # Check help option
      if parsed_arguments[:options].has_key?(:help)
        show_help(command)
        exit 1
      end

      # Check verbose option
      if parsed_arguments[:options].has_key?(:verbose)
        Nanoc::CLI::Logger.instance.level = :low
      end

      # Set VCS if possible
      set_vcs(parsed_arguments[:options][:vcs])

      # Find and run command
      command.run(parsed_arguments[:options], parsed_arguments[:arguments])
    end

    # Returns the command with the given name.
    def command_named(name)
      # Find by exact name or alias
      command = @commands.find { |c| c.name == name or c.aliases.include?(name) }
      return command unless command.nil?

      # Find by approximation
      commands = @commands.select { |c| c.name[0, name.length] == name }
      if commands.length > 1
        $stderr.puts "nanoc: '#{name}' is ambiguous:"
        $stderr.puts "  #{commands.map { |c| c.name }.join(' ') }"
        exit 1
      elsif commands.length == 0
        $stderr.puts "nanoc: unknown command '#{name}'\n"
        show_help
        exit 1
      else
        return commands[0]
      end
    end

    # Shows the help text for the given command, or shows the general help
    # text if no command is given.
    def show_help(command=nil)
      if command.nil?
        @help_command.run([], [])
      else
        @help_command.run([], [ command.name ])
      end
    end

    # Helper function which can be called when a command is executed that
    # requires a site, such as the compile command.
    def require_site
      if site.nil?
        $stderr.puts 'The current working directory does not seem to be a ' +
                     'valid/complete nanoc site directory; aborting.'
        exit 1
      end
    end

    # Gets the site (Nanoc::Site) in the current directory and loads its data.
    def site
      # Load site if possible
      if File.file?('config.yaml') and @site.nil?
        begin
          @site = Nanoc::Site.new(YAML.load_file('config.yaml'))
          @site.load_data
        rescue Nanoc::Errors::UnknownDataSourceError => e
          $stderr.puts "Unknown data source: #{e}"
          exit 1
        rescue Nanoc::Errors::UnknownRouterError => e
          $stderr.puts "Unknown router: #{e}"
          exit 1
        rescue Exception => e
          $stderr.puts "ERROR: An exception occured while loading this site."
          $stderr.puts
          $stderr.puts "If you think this is a bug in nanoc, please do report it at " +
                       "<http://nanoc.stoneship.org/trac/newticket> -- thanks!"
          $stderr.puts
          $stderr.puts 'Message:'
          $stderr.puts '  ' + e.message
          $stderr.puts
          $stderr.puts 'Backtrace:'
          $stderr.puts e.backtrace.map { |t| '  - ' + t }.join("\n")
          exit 1
        end
      end

      @site
    end

    # Sets the data source's VCS to the VCS with the given name. Does nothing
    # when the site's data source does not support VCSes (i.e. does not
    # implement #vcs=).
    def set_vcs(vcs_name)
      # Skip if not possible
      return if vcs_name.nil?
      return if site.nil? or !site.data_source.respond_to?(:vcs=)

      # Find VCS
      vcs_class = Nanoc::VCS.named(vcs_name.to_sym)
      if vcs_class.nil?
        $stderr.puts "A VCS named #{vcs_name} was not found; aborting."
        exit 1
      end

      # Set VCS
      site.data_source.vcs = vcs_class.new
    end

    # Returns the list of global option definitions, which currently include
    # the --help and --version options.
    def global_option_definitions
      [
        {
          :long => 'help', :short => 'h', :argument => :forbidden,
          :desc => 'show this help message and quit'
        },
        {
          :long => 'version', :short => 'v', :argument => :forbidden,
          :desc => 'show version information and quit'
        }
      ]
    end

  protected

    def create_commands
      @commands = []

      # Find all command classes
      command_classes = []
      ObjectSpace.each_object(Class) do |klass|
        command_classes << klass if klass < Nanoc::CLI::Command
      end

      # Create commands
      command_classes.each do |klass|
        if klass.to_s == 'Nanoc::CLI::HelpCommand'
          @help_command = HelpCommand.new
          @commands << @help_command
        else
          @commands << klass.new
        end
      end

      # Set base
      @commands.each { |c| c.base = self }
    end

  end

end
