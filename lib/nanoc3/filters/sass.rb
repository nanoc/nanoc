# encoding: utf-8

module Nanoc3::Filters
  class Sass < Nanoc3::Filter

    # Runs the content through [Sass](http://sass-lang.com/).
    # Parameters passed to this filter will be passed on to Sass.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'sass'

      # Get options
      options = params.merge(:filename => filename)

      # Get result
      ::Sass::Engine.new(content, options).render
    end

  end
end
