# encoding: utf-8

module Nanoc::CLI

  # An abstract superclass for commands that can be executed. These are not
  # the same as Cri commands, but are used in conjuction with Cri commands.
  # nanoc commands will be called by Cri commands and will perform the actual
  # execution of the command, as well as perform error handling if necessary.
  class Command

    # @return [Hash] A hash contain the options and their values
    attr_reader :options

    # @return [Array] The list of arguments
    attr_reader :arguments

    # @return [Cri::Command] The Cri command
    attr_reader :command

    # @param [Hash] options A hash contain the options and their values
    #
    # @param [Array] arguments The list of arguments
    #
    # @param [Cri::Command] command The Cri command
    def initialize(options, arguments, command)
      @options   = options
      @arguments = arguments
      @command   = command
    end

    # Runs the command with the given options, arguments and Cri command. This
    # is a convenience method so that no individual command needs to be
    # created.
    #
    # @param [Hash] options A hash contain the options and their values
    #
    # @param [Array] arguments The list of arguments
    #
    # @param [Cri::Command] command The Cri command
    #
    # @return [void]
    def self.call(options, arguments, command)
      self.new(options, arguments, command).call
    end

    # Runs the command.
    #
    # @return [void]
    def call
      # Set exit handler
      [ 'INT', 'TERM' ].each do |signal|
        Signal.trap(signal) do
          puts
          exit!(0)
        end
      end

      # Set attributes

      # Run
      self.run
    rescue Interrupt => e
      exit(1)
    rescue StandardError, ScriptError => e
      self.print_error(e)
      exit(1)
    end

    # Performs the actual execution of the command.
    #
    # @return [void]
    #
    # @abstract
    def run
    end

  protected

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc::CLI.debug?
    def debug?
      Nanoc::CLI.debug?
    end

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
      if self.stack.empty?
        $stderr.puts "  (empty)"
      else
        self.stack.reverse.each do |obj|
          if obj.is_a?(Nanoc::ItemRep)
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
        return nil if matches.size == 0
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

    # Asserts that the current working directory contains a site
    # ({Nanoc::Site} instance). If no site is present, prints an error
    # message and exits.
    #
    # @return [void]
    def require_site
      @site = nil
      if site.nil?
        $stderr.puts 'The current working directory does not seem to be a ' +
                     'valid/complete nanoc site directory; aborting.'
        exit 1
      end
    end

    # Gets the site ({Nanoc::Site} instance) in the current directory and
    # loads its data.
    #
    # @return [Nanoc::Site] The site in the current working directory
    def site
      # Load site if possible
      @site ||= nil
      if File.file?('config.yaml') && @site.nil?
        begin
          @site = Nanoc::Site.new('.')
        rescue Nanoc::Errors::UnknownDataSource => e
          $stderr.puts "Unknown data source: #{e}"
          exit 1
        end
      end

      @site
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
      vcs_class = Nanoc::Extra::VCS.named(vcs_name.to_sym)
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

    # @return [Array] The compilation stack.
    def stack
      (self.site && self.site.compiler.stack) || []
    end

  end

end
