module Nanoc::CLI

  # Nanoc::CLI::Base is the central class representing a commandline nanoc
  # tool. It has a list of commands, and is linked to a specific nanoc site.
  class Base < Cri::Base

    attr_reader :commands, :site

    # Creates a new instance of the commandline nanoc tool.
    def initialize
      super('nanoc')

      # Add help command
      self.help_command = Nanoc::CLI::HelpCommand.new
      add_command(self.help_command)

      # Add other commands
      add_command(Nanoc::CLI::AutocompileCommand.new)
      add_command(Nanoc::CLI::CompileCommand.new)
      add_command(Nanoc::CLI::CreateLayoutCommand.new)
      add_command(Nanoc::CLI::CreatePageCommand.new)
      add_command(Nanoc::CLI::CreateSiteCommand.new)
      add_command(Nanoc::CLI::CreateTemplateCommand.new)
      add_command(Nanoc::CLI::InfoCommand.new)
      add_command(Nanoc::CLI::SwitchCommand.new)
      add_command(Nanoc::CLI::UpdateCommand.new)
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
      vcs_class = Nanoc::Extra::VCS.named(vcs_name.to_sym)
      if vcs_class.nil?
        $stderr.puts "A VCS named #{vcs_name} was not found; aborting."
        exit 1
      end

      # Set VCS
      site.data_source.vcs = vcs_class.new
    end

    # Returns the list of global option definitionss.
    def global_option_definitions
      [
        {
          :long => 'help', :short => 'h', :argument => :forbidden,
          :desc => 'show this help message and quit'
        },
        {
          :long => 'verbose', :short => 'V', :argument => :forbidden,
          :desc => 'make nanoc output more detailed'
        },
        {
          :long => 'version', :short => 'v', :argument => :forbidden,
          :desc => 'show version information and quit'
        }
      ]
    end

    def handle_option(option)
      # Handle version option
      if option == :version
        puts "nanoc #{Nanoc::VERSION} (c) 2007-2009 Denis Defreyne."
        puts "Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) running on #{RUBY_PLATFORM}"
        exit 0
      # Handle help option
      elsif option == :help
        show_help
        exit 0
      end
    end

  end

end
