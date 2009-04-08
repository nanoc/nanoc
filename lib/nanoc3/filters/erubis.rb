module Nanoc3::Filters
  class Erubis < Nanoc3::Filter

    def run(content)
      require 'erubis'

      # Create context
      context = ::Nanoc3::Extra::Context.new(assigns)

      # Get result
      ::Erubis::Eruby.new(content, :filename => filename).result(context.get_binding { assigns[:content] })
    end

  end
end
