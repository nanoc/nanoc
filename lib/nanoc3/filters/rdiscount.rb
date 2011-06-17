# encoding: utf-8

require 'rdiscount'

module Nanoc3::Filters
  class RDiscount < Nanoc3::Filter

    # Runs the content through [RDiscount](http://github.com/rtomayko/rdiscount).
    #
    # @option params [Array] symbol ([]) A list of RDiscount extensions
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      extensions = params[:extensions] || []

      ::RDiscount.new(content, *extensions).to_html
    end

  end
end
