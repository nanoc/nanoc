# encoding: utf-8

module Nanoc::Filters

  class Mustache < Nanoc::Filter

    identifier :mustache

    requires 'mustache'

    # Runs the content through
    # [Mustache](http://github.com/defunkt/mustache). This method takes no
    # options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      context = item.attributes.merge({ :yield => assigns[:content] })
      ::Mustache.render(content, context)
    end

  end

end
