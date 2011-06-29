# encoding: utf-8

require 'mustache'

module Nanoc::Filters

  # @since 3.2.0
  class Mustache < Nanoc::Filter

    # Runs the content through
    # [Mustache](http://github.com/defunkt/mustache). This method takes no
    # options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Get result
      ::Mustache.render(content, item.attributes)
    end

  end

end
