module Nanoc::Filters
  class ERB < Nanoc::Filter

    identifiers :erb

    def run(content)
      require 'erb'

      # Create context
      context = ::Nanoc::Extra::Context.new(assigns)

      # Get result
      erb = ::ERB.new(content)
      erb.filename = filename
      erb.result(context.get_binding)
    end

  end
end
