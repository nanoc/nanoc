module Nanoc::Filters
  class Maruku < Nanoc::Filter

    identifier :maruku

    def run(content)
      require 'maruku'

      # Get result
      ::Maruku.new(content).to_html
    end

  end
end
