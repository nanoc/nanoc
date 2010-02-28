# encoding: utf-8

module Nanoc3::Filters
  class Kramdown < Nanoc3::Filter

    def run(content, params={})
      require 'kramdown'

      # Get result
      ::Kramdown::Document.new(content, params).to_html
    end

  end
end
