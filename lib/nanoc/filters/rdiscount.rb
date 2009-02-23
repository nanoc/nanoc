module Nanoc::Filters
  class RDiscount < Nanoc::Filter

    identifier :rdiscount

    def run(content)
      require 'rdiscount'

      ::RDiscount.new(content).to_html
    end

  end
end
