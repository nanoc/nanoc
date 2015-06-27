module Nanoc::Helpers
  # Contains several useful text-related helper functions.
  module Text
    # Returns an excerpt for the given string. HTML tags are ignored, so if
    # you don't want them to turn up, they should be stripped from the string
    # before passing it to the excerpt function.
    #
    # @param [String] string The string for which to build an excerpt
    #
    # @param [Number] length The maximum number of characters
    #   this excerpt can contain, including the omission.
    #
    # @param [String] omission The string to append to the
    #   excerpt when the excerpt is shorter than the original string
    #
    # @return [String] The excerpt of the given string
    def excerptize(string, length: 25, omission: '...')
      if string.length > length
        excerpt_length = [0, length - omission.length].max
        string[0...excerpt_length] + omission
      else
        string
      end
    end

    # Strips all HTML tags out of the given string.
    #
    # @param [String] string The string from which to strip all HTML
    #
    # @return [String] The given string with all HTML stripped
    def strip_html(string)
      # FIXME: will need something more sophisticated than this, because it sucks
      string.gsub(/<[^>]*(>+|\s*\z)/m, '').strip
    end
  end
end
