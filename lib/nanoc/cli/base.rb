module Nanoc::CLI

  class Base

    attr_reader :commands, :site

    def initialize
      create_commands
    end

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
          puts "illegal option -- #{e}"
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
        puts "illegal option -- #{e}"
        exit 1
      rescue Nanoc::CLI::OptionParser::OptionRequiresAnArgumentError => e
        puts "option requires an argument -- #{e}"
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

      # Find and run command
      command.run(parsed_arguments[:options], parsed_arguments[:arguments])
    end

    def command_named(name)
      # Find by exact name or alias
      command = @commands.find { |c| c.name == name or c.aliases.include?(name) }
      return command unless command.nil?

      # Find by approximation
      commands = @commands.select { |c| c.name[0, name.length] == name }
      if commands.length > 1
        puts "nanoc: '#{name}' is ambiguous:"
        puts "  #{commands.map { |c| c.name }.join(' ') }"
        exit 1
      elsif commands.length == 0
        puts "nanoc: unknown command '#{name}'\n"
        show_help
        exit 1
      else
        return commands[0]
      end
    end

    def show_help(command=nil)
      if command.nil?
        @help_command.run([], [])
      else
        @help_command.run([], [ command.name ])
      end
    end

    def require_site
      if site.nil?
        puts 'The current working directory does not seem to be a ' +
             'valid/complete nanoc site directory; aborting.'
        exit 1
      end
    end

    def site
      # Load site if possible
      if File.file?('config.yaml') and @site.nil?
        begin
          @site = Nanoc::Site.new(YAML.load_file('config.yaml'))
          @site.load_data
        rescue Nanoc::UnknownDataSourceError => e
          puts "Unknown data source: #{e}"
          exit 1
        rescue Nanoc::UnknownRouterError => e
          puts "Unknown router: #{e}"
          exit 1
        end
      end

      @site
    end

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

      # Create specific commands
      @help_command = HelpCommand.new
      @commands << @help_command

      # Create general commands
      @commands << AutocompileCommand.new
      @commands << CompileCommand.new
      @commands << CreateLayoutCommand.new
      @commands << CreatePageCommand.new
      @commands << CreateSiteCommand.new
      @commands << CreateTemplateCommand.new
      @commands << InfoCommand.new
      @commands << SetupCommand.new

      # Set base
      @commands.each { |c| c.base = self }
    end

  end

end
