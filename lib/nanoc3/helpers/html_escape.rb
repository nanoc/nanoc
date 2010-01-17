# encoding: utf-8

module Nanoc3::Helpers

  # Contains functionality for HTML-escaping strings.
  module HTMLEscape

    # Returns the HTML-escaped representation of the given string. Only `&`,
    # `<`, `>` and `"` are escaped.
    #
    # @param [String] string The string to escape
    #
    # @return [String] The escaped string
    def html_escape(string)
      string.gsub('&', '&amp;').
             gsub('<', '&lt;').
             gsub('>', '&gt;').
             gsub('"', '&quot;')
    end

    alias h html_escape

  end

end
