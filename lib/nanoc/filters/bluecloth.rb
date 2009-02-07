module Nanoc::Filters
  class BlueCloth < Nanoc::Filter

    identifier :bluecloth

    def run(content)
      require 'bluecloth'

      ::BlueCloth.new(content).to_html
    end

  end
end
