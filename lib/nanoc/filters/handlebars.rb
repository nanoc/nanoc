# encoding: utf-8

require 'handlebars'

module Nanoc::Filters

  # @since 3.4.0
  class Handlebars < Nanoc::Filter

    # Runs the content through
    # [Handlebars](http://handlebarsjs.com/) using
	  # [Handlebars.rb](https://github.com/cowboyd/handlebars.rb).
	  # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      context = item.attributes.dup
      context[:item]   = assigns[:item].attributes
      context[:layout] = assigns[:layout].attributes
      context[:config] = assigns[:config]
      context[:yield]  = assigns[:content]

      ::Handlebars.compile(content).call(context)
    end

  end

end
