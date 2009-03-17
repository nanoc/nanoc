module Nanoc3::Filters
  class ERB < Nanoc3::Filter

    identifier :erb

    def run(content)
      require 'erb'

      # Create context
      context = ::Nanoc3::Extra::Context.new(assigns)

      # Get result
      erb = ::ERB.new(content)
      erb.filename = filename
      erb.result(context.get_binding)
    end

  end
end
