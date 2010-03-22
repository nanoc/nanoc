# encoding: utf-8

module Nanoc3::Filters
  class RubyPants < Nanoc3::Filter

    # Runs the content through [RubyPants](http://chneukirchen.org/blog/static/projects/rubypants.html).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'rubypants'

      # Get result
      ::RubyPants.new(content).to_html
    end

  end
end
