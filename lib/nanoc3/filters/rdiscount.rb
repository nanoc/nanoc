# encoding: utf-8

module Nanoc3::Filters
  class RDiscount < Nanoc3::Filter

    # Runs the content through [RDiscount](http://github.com/rtomayko/rdiscount).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'rdiscount'

      extensions = params[:extensions] || []

      ::RDiscount.new(content, *extensions).to_html
    end

  end
end
