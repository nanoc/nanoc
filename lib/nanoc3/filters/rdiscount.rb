module Nanoc3::Filters
  class RDiscount < Nanoc3::Filter

    identifier :rdiscount

    def run(content)
      require 'rdiscount'

      ::RDiscount.new(content).to_html
    end

  end
end
