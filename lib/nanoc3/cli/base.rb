# encoding: utf-8

module Nanoc3::CLI

  class Base < Cri::Base

    def initialize
      super('nanoc3')

      # Add help command
      self.help_command = Nanoc3::CLI::Commands::Help.new
      add_command(self.help_command)

      # Add other commands
      add_command(Nanoc3::CLI::Commands::Autocompile.new)
      add_command(Nanoc3::CLI::Commands::Compile.new)
      add_command(Nanoc3::CLI::Commands::CreateLayout.new)
      add_command(Nanoc3::CLI::Commands::CreateItem.new)
      add_command(Nanoc3::CLI::Commands::CreateSite.new)
      add_command(Nanoc3::CLI::Commands::Info.new)
      add_command(Nanoc3::CLI::Commands::Update.new)
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

    # Gets the site (Nanoc3::Site) in the current directory and loads its data.
    def site
      # Load site if possible
      if File.file?('config.yaml') && (!self.instance_variable_defined?(:@site) || @site.nil?)
        begin
          @site = Nanoc3::Site.new(YAML.load_file('config.yaml'))
        rescue Nanoc3::Errors::UnknownDataSource => e
          $stderr.puts "Unknown data source: #{e}"
          exit 1
        rescue StandardError, ScriptError => error
          # Header
          $stderr.puts '+--- /!\ ERROR /!\ -------------------------------------------+'
          $stderr.puts '| An exception occured while loading the site. If you think   |'
          $stderr.puts '| this is a bug in nanoc, please do report it at              |'
          $stderr.puts '| <http://projects.stoneship.org/trac/nanoc/newticket> --     |'
          $stderr.puts '| thanks in advance!                                          |'
          $stderr.puts '+-------------------------------------------------------------+'

          # Exception
          $stderr.puts
          $stderr.puts '=== MESSAGE:'
          $stderr.puts
          $stderr.puts "#{error.class}: #{error.message}"

          # Backtrace
          require 'enumerator'
          $stderr.puts
          $stderr.puts '=== BACKTRACE:'
          $stderr.puts
          $stderr.puts error.backtrace.to_enum(:each_with_index).map { |item, index| "  #{index}. #{item}" }.join("\n")

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
      vcs_class = Nanoc3::Extra::VCS.named(vcs_name.to_sym)
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
          :long => 'no-color', :short => 'C', :argument => :forbidden,
          :desc => 'disable color'
        },
        {
          :long => 'version', :short => 'v', :argument => :forbidden,
          :desc => 'show version information and quit'
        },
        {
          :long => 'verbose', :short => 'V', :argument => :forbidden,
          :desc => 'make nanoc output more detailed'
        },
        {
          :long => 'debug', :short => 'd', :argument => :forbidden,
          :desc => 'enable debugging (set $DEBUG to true)'
        },
        {
          :long => 'warn', :short => 'w', :argument => :forbidden,
          :desc => 'enable warnings'
        }
      ]
    end

    def handle_option(option)
      case option
      when :version
        puts "nanoc #{Nanoc3::VERSION} (c) 2007-2009 Denis Defreyne."
        puts "Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) running on #{RUBY_PLATFORM}"
        exit 0
      when :verbose
        Nanoc3::CLI::Logger.instance.level = :low
      when :debug
        $DEBUG = true
      when :warn
        $-w = true
      when :'no-color'
        Nanoc3::CLI::Logger.instance.color = false
      when :help
        show_help
        exit 0
      end
    end

  end

end
