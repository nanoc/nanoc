# encoding: utf-8

module Nanoc3::Filters
  class RedCloth < Nanoc3::Filter

    def run(content, params={})
      require 'redcloth'

      # Get result
      ::RedCloth.new(content).to_html
    end

  end
end
