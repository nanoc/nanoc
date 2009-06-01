# encoding: utf-8

module Nanoc3::Filters
  class BlueCloth < Nanoc3::Filter

    def run(content, params={})
      require 'bluecloth'

      ::BlueCloth.new(content).to_html
    end

  end
end
