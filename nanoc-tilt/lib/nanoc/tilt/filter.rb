# frozen_string_literal: true

module Nanoc
  module Tilt
    class Filter < Nanoc::Filter
      identifier :tilt

      # Runs the content through [Tilt](https://github.com/rtomayko/tilt).
      # Parameters passed as `:args` will be passed on to Tilt.
      #
      # @param [String] content The content to filter
      #
      # @return [String] The filtered content
      def run(content, params = {})
        # Get options
        options = params.fetch(:args, {})

        # Create context
        context = ::Nanoc::Core::Context.new(assigns)

        # Get result
        proc = assigns[:content] ? -> { assigns[:content] } : nil

        # Find Tilt template class
        ext = item.identifier.ext || item[:extension]
        template_class = ::Tilt[ext]

        # Render
        template = template_class.new(options) { content }
        template.render(context, assigns, &proc)
      end
    end
  end
end
