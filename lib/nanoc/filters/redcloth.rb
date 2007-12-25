module Nanoc::Filter::RedCloth
  class RedClothFilter < Nanoc::Filter

    identifiers :redcloth

    def run(content)
      nanoc_require 'redcloth'

      ::RedCloth.new(content).to_html
    end

  end
end
