# encoding: utf-8

module Nanoc3::Filters
  class Mustache < Nanoc3::Filter

    # Runs the content through
    # [Mustache](http://github.com/defunkt/mustache). This method takes no
    # options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    #
    # @since 3.2.0
    def run(content, params={})
      require 'mustache'

      # Get result
      ::Mustache.render(content, item.attributes)
    end

  end
end
