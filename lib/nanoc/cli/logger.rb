require 'singleton'

module Nanoc::CLI

  # Nanoc::CLI::Logger is a singleton class responsible for generating
  # feedback in the terminal.
  class Logger

    ACTION_COLORS = {
      :create     => "\e[1m" + "\e[32m", # bold + green
      :update     => "\e[1m" + "\e[33m", # bold + yellow
      :identical  => "\e[1m",            # bold
      :skip       => "\e[1m"             # bold
    }

    include Singleton

    # The log leve, which can be :high, :low or :off (which will log all
    # messages, only high-priority messages, or no messages at all,
    # respectively).
    attr_accessor :level

    def initialize # :nodoc:
      @level = :high
    end

    # Logs a file-related action.
    #
    # +level+:: The importance of this action. Can be :high or :low.
    #
    # +action+:: The kind of file action. Can be :create, :update or
    #            :identical.
    #
    # +path+:: The path to the file the action was performed on.
    def file(level, action, path)
      log(
        level,
        '%s%12s%s  %s' % [
          ACTION_COLORS[action.to_sym],
          action,
          "\e[0m", path
        ]
      )
    end

    # Logs a message.
    #
    # +level+:: The importance of this message. Can be :high or :low.
    #
    # +s+:: The message to be logged.
    #
    # +io+:: The IO instance to which the message will be written. Defaults to
    #        standard output.
    def log(level, s, io=$stdout)
      # Don't log when logging is disabled
      return if @level == :off

      # Log when level permits it
      io.puts(s) if (@level == :low or @level == level)
    end

  end

end
