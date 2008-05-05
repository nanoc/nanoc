module Nanoc::Filters
  class Erubis < Nanoc::Filter

    identifiers :eruby

    def run(content)
      # Load requirements
      nanoc_require 'erubis'

      # Get result
      ::Erubis::Eruby.new(content).evaluate(assigns)
    end

  end
end
