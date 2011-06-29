# encoding: utf-8

require 'rubypants'

module Nanoc::Filters
  class RubyPants < Nanoc::Filter

    # Runs the content through [RubyPants](http://chneukirchen.org/blog/static/projects/rubypants.html).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Get result
      ::RubyPants.new(content).to_html
    end

  end
end
