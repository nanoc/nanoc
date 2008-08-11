module Nanoc::Filters
  class RDiscount < Nanoc::Filter

    identifiers :rdiscount

    def run(content)
      require 'rdiscount'

      ::RDiscount.new(content).to_html
    end

  end
end
