# encoding: utf-8

module Nanoc3::CLI

  # @todo Document
  class Command

    # @todo Document
    attr_reader :base

    # @todo Document
    attr_reader :options

    # @todo Document
    attr_reader :arguments

    # @todo Document
    attr_reader :command

    def initialize
      @base ||= Nanoc3::CLI.base
    end

    # @todo Document
    def self.call(options, arguments, command)
      self.new.call(options, arguments, command)
    end

    # @todo Document
    def call(options, arguments, command)
      # Set exit handler
      [ 'INT', 'TERM' ].each do |signal|
        Signal.trap(signal) do
          puts
          exit!(0)
        end
      end

      # Set attributes
      @options   = options
      @arguments = arguments
      @command   = command

      # Run
      self.run
    rescue Interrupt => e
      exit(1)
    rescue StandardError, ScriptError => e
      self.print_error(e)
      exit(1)
    end

    # @todo Document
    #
    # @abstract
    def run
    end

  protected

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
  
  end

end
