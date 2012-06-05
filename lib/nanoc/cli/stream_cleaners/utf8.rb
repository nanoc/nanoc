# encoding: utf-8

module Nanoc::CLI::StreamCleaners

  # Simplifies output by replacing UTF-8 characters with their ASCII decompositions.
  class UTF8 < Abstract

    # @see Nanoc::CLI::StreamCleaners::Abstract#clean
    def clean(s)
      # FIXME this decomposition is not generally usable
      s.gsub(/“|”/, '"').gsub(/‘|’/, '\'').gsub('…', '...').gsub('©', '(c)')
    end

  end

end
