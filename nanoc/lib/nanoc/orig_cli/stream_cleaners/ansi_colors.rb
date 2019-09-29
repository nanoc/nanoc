# frozen_string_literal: true

module Nanoc::OrigCLI::StreamCleaners
  # Removes ANSI color escape sequences.
  #
  # @api private
  class ANSIColors < Abstract
    # @see Nanoc::OrigCLI::StreamCleaners::Abstract#clean
    def clean(str)
      str.gsub(/\e\[.+?m/, '')
    end
  end
end
