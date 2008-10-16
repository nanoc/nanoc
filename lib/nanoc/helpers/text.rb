module Nanoc::Helpers

  # Nanoc::Helpers::Text contains several useful text-related helper functions.
  module Text

    # Returns an excerpt for the given string. HTML tags are ignored, so if
    # you don't want them to turn up, they should be stripped from the string
    # before passing it to the excerpt function.
    #
    # +params+ is a hash where the following keys can be set:
    #
    # +length+:: The maximum number of characters this excerpt can contain,
    #            including the omission. Defaults to 25.
    #
    # +omission+:: The string to append to the excerpt when the excerpt is
    #              shorter than the original string. Defaults to '...' (but in
    #              HTML, you may want to use something more fancy, like
    #              '&hellip;').
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
    def strip_html(string)
      # FIXME will need something more sophisticated than this, because it sucks
      string.gsub(/<[^>]*(>+|\s*\z)/m, '').strip
    end

  end

end
