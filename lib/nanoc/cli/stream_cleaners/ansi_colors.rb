module Nanoc::CLI::StreamCleaners
  # Removes ANSI color escape sequences.
  #
  # @api private
  class ANSIColors < Abstract
    # @see Nanoc::CLI::StreamCleaners::Abstract#clean
    def clean(s)
      s.is_a?(String) ? s.gsub(/\e\[.+?m/, '') : s
    end
  end
end
