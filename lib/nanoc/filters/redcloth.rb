module Nanoc::Filters
  class RedCloth < Nanoc::Filter

    identifiers :redcloth

    def run(content)
      # Load requirements
      nanoc_require 'redcloth'

      # Get result
      ::RedCloth.new(content).to_html
    end

  end
end
