# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Erubi < Nanoc::Filter
    identifier :erubi

    requires 'erubi'

    # Runs the content through [Erubi](https://github.com/jeremyevans/erubi).
    # To prevent single quote escaping use :escapefunc => 'Nanoc::Helpers::HTMLEscape.html_escape'
    # See the Erubi documentation for more options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Create context
      context = ::Nanoc::Core::Context.new(assigns)

      # Get binding
      proc = assigns[:content] ? -> { assigns[:content] } : nil
      assigns_binding = context.get_binding(&proc)

      # Get result
      engine_opts = { bufvar: '_erbout', filename: }.merge(params)
      engine = ::Erubi::Engine.new(content, engine_opts)
      eval(engine.src, assigns_binding, filename)
    end
  end
end
