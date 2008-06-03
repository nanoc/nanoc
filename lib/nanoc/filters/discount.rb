module Nanoc::Filters
  class Discount < Nanoc::Filter

    identifiers :discount

    def run(content)
      require 'discount'

      ::Discount.new(content).to_html
    end

  end
end
