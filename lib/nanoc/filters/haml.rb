module Nanoc::Filters
  class Haml < Nanoc::Filter

    identifiers :haml
    extensions  '.haml'

    def run(content)
      require 'haml'

      # Get options
      options = @page.attribute_named(:haml_options) || {}

      # Create context
      context = ::Nanoc::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns)
    end

  end
end
