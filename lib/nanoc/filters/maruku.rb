# encoding: utf-8

require 'maruku'

module Nanoc::Filters
  class Maruku < Nanoc::Filter

    # Runs the content through [Maruku](http://maruku.rubyforge.org/).
    # Parameters passed to this filter will be passed on to Maruku.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Get result
      ::Maruku.new(content, params).to_html
    end

  end
end
