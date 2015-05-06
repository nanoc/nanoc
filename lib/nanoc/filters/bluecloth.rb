# encoding: utf-8

module Nanoc::Filters
  # @api private
  class BlueCloth < Nanoc::Filter
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
