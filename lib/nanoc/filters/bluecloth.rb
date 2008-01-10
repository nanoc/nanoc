module Nanoc::Filters
  class BlueClothFilter < Nanoc::Filter

    identifiers :bluecloth

    def run(content)
      nanoc_require 'bluecloth'

      ::BlueCloth.new(content).to_html
    end

  end
end
