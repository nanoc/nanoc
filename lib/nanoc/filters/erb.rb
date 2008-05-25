module Nanoc::Filters
  class ERB < Nanoc::Filter

    identifiers :erb
    extensions  '.erb', '.rhtml'

    def run(content)
      require 'erb'

      # Create context
      context = ::Nanoc::Context.new(assigns)

      # Get result
      ::ERB.new(content).result(context.get_binding)
    end

  end
end
