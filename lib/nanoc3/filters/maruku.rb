# encoding: utf-8

module Nanoc3::Filters
  class Maruku < Nanoc3::Filter

    def run(content, params={})
      require 'maruku'

      # Get result
      ::Maruku.new(content, params).to_html
    end

  end
end
