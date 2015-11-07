module Nanoc::Filters
  # @api private
  class RDiscount < Nanoc::Filter
    requires 'rdiscount'

    # Runs the content through [RDiscount](http://github.com/rtomayko/rdiscount).
    #
    # @option params [Array] :extensions ([]) A list of RDiscount extensions
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      extensions = params[:extensions] || []

      ::RDiscount.new(content, *extensions).to_html
    end
  end
end
