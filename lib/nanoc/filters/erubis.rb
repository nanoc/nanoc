module Nanoc::Filters
  class Erubis < Nanoc::Filter

    identifiers :erubis

    def run(content)
      require 'erubis'

      # Get result
      ::Erubis::Eruby.new(content).evaluate(assigns)
    end

  end
end
