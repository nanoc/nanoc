module Nanoc::Filters
  class ERB < Nanoc::Filter

    identifier :erb

    def run(content)
      require 'erb'

      # Create context
      context = ::Nanoc::Extra::Context.new(assigns)

      # Get result
      ::ERB.new(content).result(context.get_binding)
    end

  end
end
