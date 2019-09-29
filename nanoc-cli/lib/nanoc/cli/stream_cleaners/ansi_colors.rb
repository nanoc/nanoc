# frozen_string_literal: true

module Nanoc
  module CLI
    module StreamCleaners
      # Removes ANSI color escape sequences.
      class ANSIColors < Abstract
        # @see Nanoc::CLI::StreamCleaners::Abstract#clean
        def clean(str)
          str.gsub(/\e\[.+?m/, '')
        end
      end
    end
  end
end
