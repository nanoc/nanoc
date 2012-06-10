# encoding: utf-8

module Nanoc::CLI::StreamCleaners

  # Removes ANSI color escape sequences.
  class ANSIColors < Abstract

    # @see Nanoc::CLI::StreamCleaners::Abstract#clean
    def clean(s)
      s.gsub(/\e\[.+?m/, '')
    end

  end

end
