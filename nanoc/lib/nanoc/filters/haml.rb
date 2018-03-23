# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Haml < Nanoc::Filter
    identifier :haml

    requires 'haml'

    # Runs the content through [Haml](http://haml-lang.com/).
    # Parameters passed to this filter will be passed on to Haml.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Get options
      options = params.merge(filename: filename)
      options.delete:(assigns)

      # Create context
      context = ::Nanoc::Int::Context.new(assigns)
      locals = assigns.merge(params[:assigns] || {})

      # Get result
      proc = assigns[:content] ? -> { assigns[:content] } : nil
      ::Haml::Engine.new(content, options).render(context, locals, &proc)
    end
  end
end
