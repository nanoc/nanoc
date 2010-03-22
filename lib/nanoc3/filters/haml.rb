# encoding: utf-8

module Nanoc3::Filters
  class Haml < Nanoc3::Filter

    # Runs the content through [Haml](http://haml-lang.com/).
    # Parameters passed to this filter will be passed on to Haml.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'haml'

      # Get options
      options = params.merge(:filename => filename)

      # Create context
      context = ::Nanoc3::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns) { assigns[:content] }
    end

  end
end
