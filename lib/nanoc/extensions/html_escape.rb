module Nanoc::Extensions

  # Nanoc::Extensions::HTMLEscape contains functionality for HTML-escaping
  # strings.
  module HTMLEscape

    # Returns the HTML-escaped representation of the given string. Only &, <,
    # > and " are escaped.
    def html_escape(string)
      string.gsub('&', '&amp;').
             gsub('<', '&lt;').
             gsub('>', '&gt;').
             gsub('"', '&quot;')
    end

    alias h html_escape

  end

end

# Include by default
include Nanoc::Extensions::HTMLEscape
