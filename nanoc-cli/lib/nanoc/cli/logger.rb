# frozen_string_literal: true

module Nanoc
  module CLI
    # Nanoc::CLI::Logger is a singleton class responsible for generating
    # feedback in the terminal.
    #
    # @api private
    class Logger
      ACTION_COLORS = {
        create: [:green],
        update: [:yellow],
        identical: [],
        cached: [],
        skip: [],
        delete: [:red],
      }.freeze

      include Singleton

      # Returns the log level, which can be :high, :low or :off (which will log
      # all messages, only high-priority messages, or no messages at all,
      # respectively).
      #
      # @return [Symbol] The log level
      attr_accessor :level

      def initialize
        @level = :high
        @mutex = Mutex.new
      end

      # Logs a file-related action.
      #
      # @param [:high, :low] level The importance of this action
      #
      # @param [:create, :update, :identical, :cached, :skip, :delete] action The kind of file action
      #
      # @param [String] name The name of the file the action was performed on
      #
      # @return [void]
      def file(level, action, name, duration = nil)
        colorizer = Nanoc::CLI::ANSIStringColorizer.new($stdout)
        colored_action = colorizer.c(action.to_s, *ACTION_COLORS[action.to_sym])

        message = format(
          '%12s  %s%s',
          colored_action,
          duration.nil? ? '' : format('[%2.2fs]  ', duration),
          name,
        )

        log(level, message)
      end

      # Logs a message.
      #
      # @param [:high, :low] level The importance of this message
      #
      # @param [String] message The message to be logged
      #
      # @return [void]
      def log(level, message)
        return if @level == :off
        return if @level != :low && @level != level

        @mutex.synchronize do
          puts(message)
        end
      end
    end
  end
end
