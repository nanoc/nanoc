# encoding: utf-8

module Nanoc3::Filters
  class Haml < Nanoc3::Filter

    def run(content, params={})
      require 'haml'

      # Get options
      options = params.merge(:filename => filename)

      # Create context
      context = ::Nanoc3::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns) { assigns[:content] }
    end

  end
end
