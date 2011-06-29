# encoding: utf-8

require 'haml'

module Nanoc::Filters
  class Haml < Nanoc::Filter

    # Runs the content through [Haml](http://haml-lang.com/).
    # Parameters passed to this filter will be passed on to Haml.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Get options
      options = params.merge(:filename => filename)

      # Create context
      context = ::Nanoc::Context.new(assigns)

      # Get result
      proc = assigns[:content] ? lambda { assigns[:content] } : nil
      ::Haml::Engine.new(content, options).render(context, assigns, &proc)
    end

  end
end
