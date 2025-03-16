# frozen_string_literal: true

module Nanoc
  module CLI
    # A simple ANSI colorizer for strings. When given a string and a list of
    # attributes, it returns a colorized string.
    #
    # @api private
    class ANSIStringColorizer
      CLEAR = "\e[0m"

      MAPPING = {
        bold: "\e[1m",

        black: "\e[30m",
        red: "\e[31m",
        green: "\e[32m",
        yellow: "\e[33m",
        blue: "\e[34m",
        magenta: "\e[35m",
        cyan: "\e[36m",
        white: "\e[37m",
      }.freeze

      def initialize(io)
        @io = io
      end

      def enabled?
        return @_enabled if defined?(@_enabled)

        @_enabled = Nanoc::CLI.enable_ansi_colors?(@io)
      end

      # @param [String] str The string to colorize
      #
      # @param [Array] attrs An array of attributes from `MAPPING` to colorize the
      #   string with
      #
      # @return [String] A string colorized using the given attributes
      def c(str, *attrs)
        if enabled?
          attrs.map { |a| MAPPING[a] }.join('') + str + CLEAR
        else
          str
        end
      end
    end
  end
end
