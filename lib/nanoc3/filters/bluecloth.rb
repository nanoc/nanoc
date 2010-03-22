# encoding: utf-8

module Nanoc3::Filters
  class BlueCloth < Nanoc3::Filter

    # Runs the content through [BlueCloth](http://deveiate.org/projects/BlueCloth).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'bluecloth'

      ::BlueCloth.new(content).to_html
    end

  end
end
