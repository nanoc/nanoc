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
      context = ::Nanoc::Int::Context.new(assigns)

      # Get binding
      proc = assigns[:content] ? -> { assigns[:content] } : nil
      assigns_binding = context.get_binding(&proc)

      # Get result
      eval(::Erubi::Engine.new(content, { bufvar: '_erbout', filename: filename }.merge(params)).src, assigns_binding)
    end
  end
end
