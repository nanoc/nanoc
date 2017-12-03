# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class BlueCloth < Nanoc::Filter
    identifier :bluecloth

    requires 'bluecloth'

    # Runs the content through [BlueCloth](http://deveiate.org/projects/BlueCloth).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      ::BlueCloth.new(content).to_html
    end
  end
end
