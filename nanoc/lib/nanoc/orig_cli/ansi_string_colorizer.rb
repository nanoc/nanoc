# frozen_string_literal: true

module Nanoc::OrigCLI
  # A simple ANSI colorizer for strings. When given a string and a list of
  # attributes, it returns a colorized string.
  #
  # @api private
  module ANSIStringColorizer
    # TODO: complete mapping
    MAPPING = {
      bold: "\e[1m",
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m",
      blue: "\e[34m",
    }.freeze

    # @param [String] str The string to colorize
    #
    # @param [Array] attrs An array of attributes from `MAPPING` to colorize the
    #   string with
    #
    # @return [String] A string colorized using the given attributes
    def self.c(str, *attrs)
      attrs.map { |a| MAPPING[a] }.join('') + str + "\e[0m"
    end
  end
end
