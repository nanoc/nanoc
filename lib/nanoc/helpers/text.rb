# encoding: utf-8

module Nanoc::Helpers

  # Contains several useful text-related helper functions.
  module Text

    # Returns an excerpt for the given string. HTML tags are ignored, so if
    # you don't want them to turn up, they should be stripped from the string
    # before passing it to the excerpt function.
    #
    # @param [String] string The string for which to build an excerpt
    #
    # @option params [Number] length (25) The maximum number of characters
    #   this excerpt can contain, including the omission.
    #
    # @option params [String] omission ("...") The string to append to the
    #   excerpt when the excerpt is shorter than the original string
    #
    # @return [String] The excerpt of the given string
    def excerptize(string, params={})
      # Initialize params
      params[:length]   ||= 25
      params[:omission] ||= '...'

      # Get excerpt
      length = params[:length] - params[:omission].length
      length = 0 if length < 0
      (string.length > params[:length] ? string[0...length] + params[:omission] : string)
    end

    # Strips all HTML tags out of the given string.
    #
    # @param [String] string The string from which to strip all HTML
    #
    # @return [String] The given string with all HTML stripped
    def strip_html(string)
      # FIXME will need something more sophisticated than this, because it sucks
      string.gsub(/<[^>]*(>+|\s*\z)/m, '').strip
    end

  end

end
