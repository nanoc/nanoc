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
      options = params.merge(
        filename:,
        outvar: '_erbout',
        disable_capture: true,
      )

      # Create context
      context = ::Nanoc::Core::Context.new(assigns)

      # Get result
      proc = assigns[:content] ? -> { assigns[:content] } : nil

      # Render
      haml_major_version = ::Haml::VERSION[0]
      case haml_major_version
      when '5'
        ::Haml::Engine.new(content, options).render(context, assigns, &proc)
      when '6'
        template = Tilt::HamlTemplate.new(options) { content }
        template.render(context, assigns, &proc)
      else
        raise Nanoc::Core::TrivialError.new(
          "Cannot run Haml filter: unsupported Haml major version: #{haml_major_version}",
        )
      end
    end
  end
end
