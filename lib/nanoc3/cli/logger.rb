# encoding: utf-8

require 'singleton'

module Nanoc3::CLI

  # Nanoc3::CLI::Logger is a singleton class responsible for generating
  # feedback in the terminal.
  class Logger

    # Maps actions (`:create`, `:update`, `:identical` and `:skip`) onto their
    # ANSI color codes.
    ACTION_COLORS = {
      :create         => "\e[1m" + "\e[32m", # bold + green
      :update         => "\e[1m" + "\e[33m", # bold + yellow
      :identical      => "\e[1m",            # bold
      :skip           => "\e[1m"             # bold
    }

    include Singleton

    # Returns the log level, which can be :high, :low or :off (which will log
    # all messages, only high-priority messages, or no messages at all,
    # respectively).
    #
    # @return [Symbol] The log level
    attr_accessor :level

    # @return [Boolean] True if color should be used, false otherwise
    attr_accessor :color
    alias_method :color?, :color

    def initialize
      @level = :high
      @color = $stdout.tty?

      # Try enabling color support on Windows
      begin
        require 'Win32/Console/ANSI' if RUBY_PLATFORM =~/mswin|mingw/
      rescue LoadError
        @color = false
      end
    end

    # Logs a file-related action.
    #
    # @param [:high, :low] level The importance of this action
    #
    # @param [:create, :update, :identical] action The kind of file action
    #
    # @param [String] name The name of the file the action was performed on
    #
    # @return [void]
    def file(level, action, identifier, duration=nil)
      log(
        level,
        '%s%12s%s  %s%s' % [
          color? ? ACTION_COLORS[action.to_sym] : '',
          action,
          color? ? "\e[0m" : '',
          duration.nil? ? '' : "[%2.2fs]  " % [ duration ],
          identifier
        ]
      )
    end

    # Logs a message.
    #
    # @param [:high, :low] level The importance of this message
    #
    # @param [String] message The message to be logged
    #
    # @param [#puts] io The stream to which the message should be written
    #
    # @return [void]
    def log(level, message, io=$stdout)
      # Don't log when logging is disabled
      return if @level == :off

      # Log when level permits it
      io.puts(message) if (@level == :low or @level == level)
    end

  end

end
