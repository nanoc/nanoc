module Nanoc::Filters
  class Maruku < Nanoc::Filter

    identifiers :maruku

    def run(content)
      nanoc_require 'maruku'

      ::Maruku.new(content).to_html
    end

  end
end
