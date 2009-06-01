# encoding: utf-8

module Nanoc3::Filters
  class RDiscount < Nanoc3::Filter

    def run(content, params={})
      require 'rdiscount'

      ::RDiscount.new(content).to_html
    end

  end
end
