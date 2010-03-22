# encoding: utf-8

module Nanoc3::Filters
  class RedCloth < Nanoc3::Filter

    # Runs the content through [RedCloth](http://redcloth.org/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'redcloth'

      # Get result
      ::RedCloth.new(content).to_html
    end

  end
end
