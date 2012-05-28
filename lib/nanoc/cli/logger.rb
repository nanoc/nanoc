# encoding: utf-8

require 'singleton'

module Nanoc::CLI

  # Nanoc::CLI::Logger is a singleton class responsible for generating
  # feedback in the terminal.
  class Logger

    # Maps actions (`:create`, `:update`, `:identical`, `:skip` and `:delete`)
    # onto their ANSI color codes.
    ACTION_COLORS = {
      :create         => "\e[1m" + "\e[32m", # bold + green
      :update         => "\e[1m" + "\e[33m", # bold + yellow
      :identical      => "\e[1m",            # bold
      :skip           => "\e[1m",            # bold
      :delete         => "\e[1m" + "\e[31m"  # bold + red
    }

    include Singleton

    # Returns the log level, which can be :high, :low or :off (which will log
    # all messages, only high-priority messages, or no messages at all,
    # respectively).
    #
    # @return [Symbol] The log level
    attr_accessor :level

    def initialize
      @level = :high
    end

    # Logs a file-related action.
    #
    # @param [:high, :low] level The importance of this action
    #
    # @param [:create, :update, :identical, :skip, :delete] action The kind of file action
    #
    # @param [String] name The name of the file the action was performed on
    #
    # @return [void]
    def file(level, action, name, duration=nil)
      log(
        level,
        '%s%12s%s  %s%s' % [
          ACTION_COLORS[action.to_sym],
          action,
          "\e[0m",
          duration.nil? ? '' : "[%2.2fs]  " % [ duration ],
          name
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
