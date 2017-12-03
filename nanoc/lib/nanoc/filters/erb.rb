# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class ERB < Nanoc::Filter
    identifier :erb

    requires 'erb'

    # Runs the content through [ERB](http://ruby-doc.org/stdlib/libdoc/erb/rdoc/classes/ERB.html).
    #
    # @param [String] content The content to filter
    #
    # @option params [Integer] :safe_level (nil) The safe level (`$SAFE`) to
    #   use while running this filter
    #
    # @option params [String] :trim_mode (nil) The trim mode to use
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Add locals
      assigns.merge!(params[:locals] || {})

      # Create context
      context = ::Nanoc::Int::Context.new(assigns)

      # Get binding
      proc = assigns[:content] ? -> { assigns[:content] } : nil
      assigns_binding = context.get_binding(&proc)

      # Get result
      safe_level = params[:safe_level]
      trim_mode = params[:trim_mode]
      erb = ::ERB.new(content, safe_level, trim_mode)
      erb.filename = filename
      erb.result(assigns_binding)
    end
  end
end
