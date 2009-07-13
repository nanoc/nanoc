# encoding: utf-8

module Nanoc3::Filters
  class Sass < Nanoc3::Filter

    def run(content, params={})
      require 'sass'

      # Get options
      options = params.merge(:filename => filename)

      # Get result
      ::Sass::Engine.new(content, options).render
    end

  end
end
