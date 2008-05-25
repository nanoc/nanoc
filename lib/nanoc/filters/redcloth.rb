module Nanoc::Filters
  class RedCloth < Nanoc::Filter

    identifiers :redcloth

    def run(content)
      require 'redcloth'

      # Get result
      ::RedCloth.new(content).to_html
    end

  end
end
