module Nanoc3::Filters
  class Haml < Nanoc3::Filter

    identifier :haml

    def run(content, params={})
      require 'haml'

      # Get options
      symbolized_params = params.inject({}) { |m,(k,v)| m.merge(k => v.to_sym) }
      options = symbolized_params
      options[:filename] = filename

      # Create context
      context = ::Nanoc3::Extra::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns)
    end

  end
end
