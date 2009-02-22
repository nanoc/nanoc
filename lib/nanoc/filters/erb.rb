module Nanoc::Filters
  class ERB < Nanoc::Filter

    identifier :erb

    def run(content)
      require 'erb'

      # Create context
      context = ::Nanoc::Extra::Context.new(assigns)

      # Get result
      erb = ::ERB.new(content)
      if assigns[:page]
        erb.filename = "page #{assigns[:_obj].path} (rep #{assigns[:_obj_rep].name})"
      elsif assigns[:asset]
        erb.filename = "asset #{assigns[:_obj].path} (rep #{assigns[:_obj_rep].name})"
      end
      erb.result(context.get_binding)
    end

  end
end
