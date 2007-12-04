module Nanoc::Filter::Textile
  class TextileFilter < Nanoc::Filter

    identifiers :textile, :redcloth

    def run(content)
      nanoc_require 'redcloth'

      ::RedCloth.new(content).to_html
    end

  end
end
