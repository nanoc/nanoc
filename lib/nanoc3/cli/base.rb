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
      'redcarpet'      => 'redcarpet',
      'redcloth'       => 'redcloth',
      'rubypants'      => 'rubypants',
      'sass'           => 'sass',
      'systemu'        => 'systemu',
      'w3c_validators' => 'w3c_validators'
    }

    def initialize
      super('nanoc3')

      @debug = false
    end

    # Returns a fully initialised base instance. It is recommended to use this
    # shared instance than to create new ones, as this will be the instance
    # that will be used when reading all code from the `lib/` directory.
    #
    # @return [Nanoc3::CLI::Base]
    def self.shared_base
      @shared_base ||= Nanoc3::CLI::Base.new
    end

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @since 3.2.0
    def debug?
      @debug
    end

    # Asserts that the current working directory contains a site
    # ({Nanoc3::Site} instance). If no site is present, prints an error
    # message and exits.
    #
    # @return [void]
    def require_site
      if site.nil?
        $stderr.puts 'The current working directory does not seem to be a ' +
                     'valid/complete nanoc site directory; aborting.'
        exit 1
      end
    end

    # Gets the site ({Nanoc3::Site} instance) in the current directory and
    # loads its data.
    #
    # @return [Nanoc3::Site] The site in the current working directory
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

    # @see ::Cri::Base#run
    def run(args)
      # Set exit handler
      [ 'INT', 'TERM' ].each do |signal|
        Signal.trap(signal) do
          puts
          exit!(0)
        end
      end

      # Load custom commands
      Dir['./lib/commands/*.rb'].each { |f| require f }

      super(args)
    rescue Interrupt => e
      exit(1)
    rescue StandardError, ScriptError => e
      print_error(e)
      exit(1)
    end

    # Prints the given error to stderr. Includes message, possible resolution
    # (see {#resolution_for}), compilation stack, backtrace, etc.
    #
    # @param [Error] error The error that should be described
    #
    # @return [void]
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
      if stack.empty?
        $stderr.puts "  (empty)"
      else
        stack.reverse.each do |obj|
          if obj.is_a?(Nanoc3::ItemRep)
            $stderr.puts "  - [item]   #{obj.item.identifier} (rep #{obj.name})"
          else # layout
            $stderr.puts "  - [layout] #{obj.identifier}"
          end
        end
      end

      # Backtrace
      $stderr.puts
      $stderr.puts '=== BACKTRACE:'
      $stderr.puts
      $stderr.puts error.backtrace.to_enum(:each_with_index).map { |item, index| "  #{index}. #{item}" }.join("\n")
    end

    # Attempts to find a resolution for the given error, or nil if no
    # resolution can be automatically obtained.
    #
    # @param [Error] error The error to find a resolution for
    #
    # @return [String] The resolution for the given error
    def resolution_for(error)
      case error
      when LoadError
        # Get gem name
        matches = error.message.match(/no such file to load -- ([^\s]+)/)
        return nil if matches.empty?
        lib_name = matches[1]
        gem_name = GEM_NAMES[$1]

        # Build message
        if gem_name
          "Try installing the '#{gem_name}' gem (`gem install #{gem_name}`) and then re-running the command."
        end
      when RuntimeError
        if error.message =~ /^can't modify frozen/
          "You attempted to modify immutable data. Some data, such as " \
          "item/layout attributes and raw item/layout content, can not " \
          "be modified once compilation has started. (This was " \
          "unintentionally possible in 3.1.x and before, but has been " \
          "disabled in 3.2.x in order to allow compiler optimisations.)"
        end
      end
    end

    # Sets the data source's VCS to the VCS with the given name. Does nothing
    # when the site's data source does not support VCSes (i.e. does not
    # implement #vcs=).
    #
    # @param [String] vcs_name The name of the VCS that should be used
    #
    # @return [void]
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

    # @return [Array] The list of global option definitions
    def global_option_definitions
      [
        {
          :long => 'help', :short => 'h', :argument => :forbidden,
          :desc => 'show this help message and quit'
        },
        {
          :long => 'color', :short => 'l', :argument => :forbidden,
          :desc => 'enable color'
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

    # @see Cri::Base#handle_option
    def handle_option(*args)
      key, value, command = *args # for backwards compatibility

      case key
      when :version
        gem_info = defined?(Gem) ? "with RubyGems #{Gem::VERSION}" : "without RubyGems"
        engine   = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"

        puts "nanoc #{Nanoc3::VERSION} (c) 2007-2011 Denis Defreyne."
        puts "Running #{engine} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} #{gem_info}"
        exit 0
      when :verbose
        Nanoc3::CLI::Logger.instance.level = :low
      when :debug
        @debug = true
      when :warn
        $-w = true
      when :color
        Nanoc3::CLI::Logger.instance.color = true
      when :'no-color'
        Nanoc3::CLI::Logger.instance.color = false
      when :help
        show_help(command)
        exit 0
      end
    end

  protected

    def stack
      (self.site && self.site.compiler.stack) || []
    end

  end

end
