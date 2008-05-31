require 'singleton'

module Nanoc::CLI

  # TODO document
  class Logger

    ACTION_COLORS = {
      :create     => "\e[1m" + "\e[32m", # bold + green
      :update     => "\e[1m" + "\e[33m", # bold + yellow
      :identical  => "\e[1m"             # bold
    }

    include Singleton

    # TODO document
    attr_accessor :level

    # TODO document
    def initialize
      @level = :high
    end

    # TODO document
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

    # TODO document
    def log(level, s, io=$stdout)
      # Don't log when logging is disabled
      return if @level == :off

      # Log when level permits it
      io.puts(s) if (@level == :low or @level == level)
    end

  end

end
