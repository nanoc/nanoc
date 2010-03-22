# encoding: utf-8

module Nanoc3::Filters
  class Maruku < Nanoc3::Filter

    # Runs the content through [Maruku](http://maruku.rubyforge.org/).
    # Parameters passed to this filter will be passed on to Maruku.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'maruku'

      # Get result
      ::Maruku.new(content, params).to_html
    end

  end
end
