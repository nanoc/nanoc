module Nanoc3::Filters
  class Erubis < Nanoc3::Filter

    identifier :erubis

    def run(content)
      require 'erubis'

      # Get result
      ::Erubis::Eruby.new(content, :filename => filename).evaluate(assigns)
    end

  end
end
