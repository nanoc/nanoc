module Nanoc3::Filters
  class RedCloth < Nanoc3::Filter

    def run(content)
      require 'redcloth'

      # Get result
      ::RedCloth.new(content).to_html
    end

  end
end
