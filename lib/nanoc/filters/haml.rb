module Nanoc::Filters
  class Haml < Nanoc::Filter

    identifiers :haml
    extensions  '.haml'

    def run(content)
      require 'haml'

      # Get options
      options = @obj_rep.attribute_named(:haml_options) || {}
      options[:filename] = filename

      # Create context
      context = ::Nanoc::Extra::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns)
    end

  end
end
