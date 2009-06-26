# encoding: utf-8

module Nanoc3::Filters
  class Less < Nanoc3::Filter

    def run(content, params={})
      require 'less'

      ::Less::Engine.new(content).to_css
    end

  end
end
