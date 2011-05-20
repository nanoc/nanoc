# encoding: utf-8

module Nanoc3::Filters
  class RDiscount < Nanoc3::Filter

    # Runs the content through [RDiscount](http://github.com/rtomayko/rdiscount).
    # This method takes optional parameters to pass along to Rdiscount.
    #
    # @content [String] content The content to filter
    #
    # @params [Hash{Symbol => Array<Symbol>}]
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'rdiscount'

      extensions = params[:extensions] || []

      ::RDiscount.new(content, *extensions).to_html
    end

  end
end
