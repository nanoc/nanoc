# frozen_string_literal: true

module Nanoc::CLI::StreamCleaners
  # Simplifies output by replacing UTF-8 characters with their ASCII decompositions.
  #
  # @api private
  class UTF8 < Abstract
    # @see Nanoc::CLI::StreamCleaners::Abstract#clean
    def clean(str)
      # FIXME: this decomposition is not generally usable
      str
        .unicode_normalize(:nfkd)
        .tr('─┼“”‘’', '-+""\'\'')
        .gsub('©', '(c)')
    end
  end
end
