module Nanoc::Filters
  class Sass < Nanoc::Filter

    identifier :sass

    def run(content)
      require 'sass'

      # Get options
      options = assigns[:_obj_rep].attribute_named(:sass_options) || {}

      # Get result
      ::Sass::Engine.new(content, options).render
    end

  end
end
