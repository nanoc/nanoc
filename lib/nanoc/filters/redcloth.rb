module Nanoc::Filters
  class RedCloth < Nanoc::Filter

    identifier :redcloth

    def run(content)
      require 'redcloth'

      # Get result
      ::RedCloth.new(content).to_html
    end

  end
end
