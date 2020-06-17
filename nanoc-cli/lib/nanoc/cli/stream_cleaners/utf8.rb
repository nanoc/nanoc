# frozen_string_literal: true

module Nanoc
  module CLI
    module StreamCleaners
      # Simplifies output by replacing UTF-8 characters with their ASCII decompositions.
      #
      class UTF8 < Abstract
        # @see Nanoc::CLI::StreamCleaners::Abstract#clean
        def clean(str)
          return str unless str.encoding.name == 'UTF-8'

          # FIXME: this decomposition is not generally usable
          str
            .unicode_normalize(:nfkd)
            .tr('─┼“”‘’', '-+""\'\'')
            .gsub('©', '(c)')
        end
      end
    end
  end
end
