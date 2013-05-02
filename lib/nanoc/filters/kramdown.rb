# encoding: utf-8

module Nanoc::Filters
  class Kramdown < Nanoc::Filter

    identifier :kramdown

    requires 'kramdown'

    # Runs the content through [Kramdown](http://kramdown.rubyforge.org/).
    # Parameters passed to this filter will be passed on to Kramdown.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Get result
      ::Kramdown::Document.new(content, params).to_html
    end

  end
end
