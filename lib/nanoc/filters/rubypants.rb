# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class RubyPants < Nanoc::Filter
    identifier :rubypants

    requires 'rubypants'

    # Runs the content through [RubyPants](http://rubydoc.info/gems/rubypants/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      # Get result
      ::RubyPants.new(content).to_html
    end
  end
end
