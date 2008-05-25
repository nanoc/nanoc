module Nanoc::Filters
  class Maruku < Nanoc::Filter

    identifiers :maruku

    def run(content)
      require 'maruku'

      # Get result
      ::Maruku.new(content).to_html
    end

  end
end
