# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class AsciiDoc < Nanoc::Filter
    identifier :asciidoc

    # Runs the content through [AsciiDoc](http://www.methods.co.nz/asciidoc/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      TTY::Command.new(printer: :null).run('asciidoc -o - -', input: content).out
    end
  end
end
