# encoding: utf-8

module Nanoc::Filters

  class Handlebars < Nanoc::Filter

    identifier :handlebars

    requires 'handlebars'

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

      handlebars = ::Handlebars::Context.new
      template = handlebars.compile(content)
      template.call(context)
    end

  end

end
