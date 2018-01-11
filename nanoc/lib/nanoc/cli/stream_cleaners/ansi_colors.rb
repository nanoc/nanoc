# frozen_string_literal: true

module Nanoc::CLI::StreamCleaners
  # Removes ANSI color escape sequences.
  #
  # @api private
  class ANSIColors < Abstract
    # @see Nanoc::CLI::StreamCleaners::Abstract#clean
    def clean(str)
      str.gsub(/\e\[.+?m/, '')
    end
  end
end
