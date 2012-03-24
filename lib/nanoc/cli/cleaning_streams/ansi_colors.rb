# encoding: utf-8

module Nanoc::CLI::CleaningStreams

  # Removes ANSI color escape sequences.
  class ANSIColors < Abstract

    # @see Nanoc::CLI::CleaningStreams::Abstract#clean
    def clean(s)
      s.gsub(/\e\[.+?m/, '')
    end

  end

end
