module Nanoc::Filters
  class Haml < Nanoc::Filter

    identifier :haml

    def run(content)
      require 'haml'

      # Get options
      options = assigns[:_obj_rep].attribute_named(:haml_options) || {}

      # Create context
      context = ::Nanoc::Extra::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns)
    end

  end
end
