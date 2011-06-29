# encoding: utf-8

module Nanoc::Helpers

  # Contains functionality for HTML-escaping strings.
  module HTMLEscape

    require 'nanoc/helpers/capturing'
    include Nanoc::Helpers::Capturing

    # Returns the HTML-escaped representation of the given string or the given
    # block. Only `&`, `<`, `>` and `"` are escaped. When given a block, the
    # contents of the block will be escaped and appended to the output buffer,
    # `_erbout`.
    #
    # @example Escaping a string
    #
    #     h('<br>')
    #     # => '&lt;br&gt;'
    #
    # @example Escaping with a block
    #
    #     <% h do %>
    #       <h1>Hello <em>world</em>!</h1>
    #     <% end %>
    #     # The buffer will now contain “&lt;h1&gt;Hello &lt;em&gt;world&lt;/em&gt;!&lt;/h1&gt;”
    #
    # @param [String] string The string to escape
    #
    # @return [String] The escaped string
    def html_escape(string=nil, &block)
      if block_given?
        # Capture and escape block
        data = capture(&block)
        escaped_data = html_escape(data)

        # Append filtered data to buffer
        buffer = eval('_erbout', block.binding)
        buffer << escaped_data
      elsif string
        string.gsub('&', '&amp;').
               gsub('<', '&lt;').
               gsub('>', '&gt;').
               gsub('"', '&quot;')
      else
        raise RuntimeError, "The #html_escape or #h function needs either a " \
          "string or a block to HTML-escape, but neither a string nor a block was given"
      end
    end

    alias h html_escape

  end

end
