# encoding: utf-8

module Nanoc::CLI

  # A simple ANSI colorizer for strings. When given a string and a list of
  # attributes, it returns a colorized string.
  module ANSIStringColorizer

    # check https://en.wikipedia.org/wiki/ANSI_escape_code
    # TODO complete font face like bold, italic, etc.
    MAPPING = {
      :bold    => "\e[1m",
      :black   => "\e[30m",
      :red     => "\e[31m",
      :green   => "\e[32m",
      :yellow  => "\e[33m",
      :blue    => "\e[34m",
      :magenta => "\e[35m",
      :cyan    => "\e[36m",
      :white   => "\e[37m"
    }

    # @param [String] s The string to colorize
    #
    # @param [Array] as An array of attributes from `MAPPING` to colorize the
    #   string with
    #
    # @return [String] A string colorized using the given attributes
    def self.c(s, *as)
      as.map { |a| MAPPING[a] }.join('') + s + "\e[0m"
    end

  end

end
