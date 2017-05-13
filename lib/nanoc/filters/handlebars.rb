# frozen_string_literal: true

module Nanoc::Filters
  # @api private
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
    def run(content, _params = {})
      context = item.attributes.dup
      context[:item]   = assigns[:item].attributes
      context[:config] = assigns[:config]
      context[:yield]  = assigns[:content]
      if assigns.key?(:layout)
        context[:layout] = assigns[:layout].attributes
      end

      handlebars = ::Handlebars::Context.new
      template = handlebars.compile(content)
      template.call(context)
    end
  end
end
