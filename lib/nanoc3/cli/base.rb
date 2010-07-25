# encoding: utf-8

module Nanoc3::CLI

  class Base < Cri::Base

    # A hash that contains the name of the gem for a given required file. If a
    # `#require` fails, the gem name is looked up in this hash.
    GEM_NAMES = {
      'adsf'           => 'adsf',
      'bluecloth'      => 'bluecloth',
      'builder'        => 'builder',
      'coderay'        => 'coderay',
      'cri'            => 'cri',
      'erubis'         => 'erubis',
      'escape'         => 'escape',
      'fssm'           => 'fssm',
      'haml'           => 'haml',
      'json'           => 'json',
      'kramdown'       => 'kramdown',
      'less'           => 'less',
      'markaby'        => 'markaby',
      'maruku'         => 'maruku',
      'mime/types'     => 'mime-types',
      'nokogiri'       => 'nokogiri',
      'rack'           => 'rack',
      'rack/cache'     => 'rack-cache',
      'rainpress'      => 'rainpress',
      'rdiscount'      => 'rdiscount',
      'redcloth'       => 'redcloth',
      'rubypants'      => 'rubypants',
      'sass'           => 'sass',
      'w3c_validators' => 'w3c_validators'
    }

    def initialize
      super('nanoc3')

      @debug = false

      # Add help command
      self.help_command = Nanoc3::CLI::Commands::Help.new
      add_command(self.help_command)

      # Add other commands
      add_command(Nanoc3::CLI::Commands::Autocompile.new)
      add_command(Nanoc3::CLI::Commands::Compile.new)
      add_command(Nanoc3::CLI::Commands::CreateLayout.new)
      add_command(Nanoc3::CLI::Commands::CreateItem.new)
      add_command(Nanoc3::CLI::Commands::CreateSite.new)
      add_command(Nanoc3::CLI::Commands::Debug.new)
      add_command(Nanoc3::CLI::Commands::Info.new)
      add_command(Nanoc3::CLI::Commands::Update.new)
      add_command(Nanoc3::CLI::Commands::View.new)
      add_command(Nanoc3::CLI::Commands::Watch.new)
    end

    def self.shared_base
      @shared_base ||= Nanoc3::CLI::Base.new
    end

    # @return [Boolean] true if debug output is enabled, false if not
    def debug?
      @debug
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
          @site = Nanoc3::Site.new('.')
        rescue Nanoc3::Errors::UnknownDataSource => e
          $stderr.puts "Unknown data source: #{e}"
          exit 1
        end
      end

      @site
    end

    # Inherited from ::Cri::Base
    def run(args)
      # Set exit handler
      [ 'INT', 'TERM' ].each do |signal|
        Signal.trap(signal) do
          puts
          exit!(0)
        end
      end

      super(args)
    rescue Interrupt => e
      exit(1)
    rescue StandardError, ScriptError => e
      print_error(e)
      exit(1)
    end

    # Prints the given error to stderr. Includes message, possible resolution,
    # compilation stack, backtrace, etc.
    def print_error(error)
      $stderr.puts

      # Header
      $stderr.puts '+--- /!\ ERROR /!\ -------------------------------------------+'
      $stderr.puts '| An exception occured while running nanoc. If you think this |'
      $stderr.puts '| is a bug in nanoc, please do report it at                   |'
      $stderr.puts '| <http://projects.stoneship.org/trac/nanoc/newticket> --     |'
      $stderr.puts '| thanks in advance!                                          |'
      $stderr.puts '+-------------------------------------------------------------+'

      # Exception and resolution (if any)
      $stderr.puts
      $stderr.puts '=== MESSAGE:'
      $stderr.puts
      $stderr.puts "#{error.class}: #{error.message}"
      resolution = self.resolution_for(error)
      $stderr.puts "#{resolution}" if resolution

      # Compilation stack
      $stderr.puts
      $stderr.puts '=== COMPILATION STACK:'
      $stderr.puts
      if ((self.site && self.site.compiler.stack) || []).empty?
        $stderr.puts "  (empty)"
      else
        self.site.compiler.stack.reverse.each do |obj|
          if obj.is_a?(Nanoc3::ItemRep)
            $stderr.puts "  - [item]   #{obj.item.identifier} (rep #{obj.name})"
          else # layout
            $stderr.puts "  - [layout] #{obj.identifier}"
          end
        end
      end

      # Backtrace
      require 'enumerator'
      $stderr.puts
      $stderr.puts '=== BACKTRACE:'
      $stderr.puts
      $stderr.puts error.backtrace.to_enum(:each_with_index).map { |item, index| "  #{index}. #{item}" }.join("\n")
    end

    # Returns a string containing hints for resolving the given error, or nil
    # if no resolution can be automatically obtained.
    def resolution_for(error)
      case error
      when LoadError
        # Get gem name
        lib_name = error.message.match(/no such file to load -- ([^\s]+)/)[1]
        gem_name = GEM_NAMES[$1]

        # Build message
        if gem_name
          "Try installing the '#{gem_name}' gem (`gem install #{gem_name}`) and then re-running the command."
        end
      end
    end

    # Sets the data source's VCS to the VCS with the given name. Does nothing
    # when the site's data source does not support VCSes (i.e. does not
    # implement #vcs=).
    def set_vcs(vcs_name)
      # Skip if not possible
      return if vcs_name.nil? || site.nil?

      # Find VCS
      vcs_class = Nanoc3::Extra::VCS.named(vcs_name.to_sym)
      if vcs_class.nil?
        $stderr.puts "A VCS named #{vcs_name} was not found; aborting."
        exit 1
      end

      site.data_sources.each do |data_source|
        # Skip if not possible
        next if !data_source.respond_to?(:vcs=)

        # Set VCS
        data_source.vcs = vcs_class.new
      end
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
          :desc => 'enable debugging'
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
        gem_info = defined?(Gem) ? "with RubyGems #{Gem::VERSION}" : "without RubyGems"

        puts "nanoc #{Nanoc3::VERSION} (c) 2007-2010 Denis Defreyne."
        puts "Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) running on #{RUBY_PLATFORM} #{gem_info}"
        exit 0
      when :verbose
        Nanoc3::CLI::Logger.instance.level = :low
      when :debug
        @debug = true
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
