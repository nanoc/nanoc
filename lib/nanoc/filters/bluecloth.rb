# encoding: utf-8

require 'bluecloth'

module Nanoc::Filters
  class BlueCloth < Nanoc::Filter

    # Runs the content through [BlueCloth](http://deveiate.org/projects/BlueCloth).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      ::BlueCloth.new(content).to_html
    end

  end
end
