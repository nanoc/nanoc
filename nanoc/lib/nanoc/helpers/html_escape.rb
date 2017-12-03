# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#filtering
  module HTMLEscape
    require 'nanoc/helpers/capturing'
    include Nanoc::Helpers::Capturing

    # @param [String] string
    #
    # @return [String]
    def html_escape(string = nil, &block)
      if block_given?
        # Capture and escape block
        data = capture(&block)
        escaped_data = html_escape(data)

        # Append filtered data to buffer
        buffer = eval('_erbout', block.binding)
        buffer << escaped_data
      elsif string
        unless string.is_a? String
          raise ArgumentError, 'The #html_escape or #h function needs either a ' \
            "string or a block to HTML-escape, but #{string.class} was given"
        end

        string
          .gsub('&', '&amp;')
          .gsub('<', '&lt;')
          .gsub('>', '&gt;')
          .gsub('"', '&quot;')
      else
        raise 'The #html_escape or #h function needs either a ' \
          'string or a block to HTML-escape, but neither a string nor a block was given'
      end
    end

    alias h html_escape
  end
end
