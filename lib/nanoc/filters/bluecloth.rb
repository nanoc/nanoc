module Nanoc::Filters
  class BlueCloth < Nanoc::Filter

    identifiers :bluecloth

    def run(content)
      nanoc_require 'bluecloth'

      ::BlueCloth.new(content).to_html
    end

  end
end
