# encoding: utf-8

module Nanoc3::CLI

  # Catches errors and prints nice diagnostic messages, then exits.
  #
  # @api private
  class ErrorHandler

    # @option params [Nanoc3::CLI::Command, nil] command The command that is
    #   currently being executed, or nil if there is none
    def initialize(params={})
      @command = params[:command]
    end

    # Enables error handling in the given block.
    #
    # @option params [Nanoc3::CLI::Command, nil] command The command that is
    #   currently being executed, or nil if there is none
    #
    # @return [void]
    def self.handle_while(params={}, &block)
      self.new(params).handle_while(&block)
    end

    # Enables error handling in the given block. This method should not be
    # called directly; use {Nanoc3::CLI::ErrorHandler.handle_while} instead.
    #
    # @return [void]
    #
    # @api private
    def handle_while(&block)
      # Set exit handler
      [ 'INT', 'TERM' ].each do |signal|
        Signal.trap(signal) do
          puts
          exit!(0)
        end
      end

      # Run
      yield
    rescue Interrupt => e
      exit(1)
    rescue StandardError, ScriptError => e
      self.print_error(e)
      exit(1)
    end

    # Prints the given error to stderr. Includes message, possible resolution
    # (see {#resolution_for}), compilation stack, backtrace, etc.
    #
    # @param [Error] error The error that should be described
    #
    # @return [void]
    def self.print_error(error)
      self.new.print_error(error)
    end

    # Prints the given error to stderr. Includes message, possible resolution
    # (see {#resolution_for}), compilation stack, backtrace, etc.
    #
    # @param [Error] error The error that should be described
    #
    # @return [void]
    def print_error(error)
      # Header
      $stderr.puts
      $stderr.puts "Captain! We’ve been hit!"

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

      # Issue link
      $stderr.puts
      $stderr.puts "If you believe this is a bug in nanoc, please do report it at"
      $stderr.puts "<https://github.com/ddfreyne/nanoc/issues/new>--thanks!"
    end

  protected

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc3::CLI.debug?
    def debug?
      Nanoc3::CLI.debug?
    end

    # @return [Nanoc3::Site] The site that is currently being processed
    def site
      @command && @command.site
    end

    # @return [Nanoc3::Compiler] The compiler for the current site
    def compiler
      site && site.compiler
    end

    # @return [Array] The current compilation stack
    def stack
      (compiler && compiler.stack) || []
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
        return nil if matches.nil?
        gem_name = GEM_NAMES[matches[1]]

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

  end

end
