module Nanoc::Filters
  class Sass < Nanoc::Filter

    identifiers :sass

    def run(content)
      require 'sass'

      # Get options
      options = @page.attribute_named(:sass_options) || {}

      # Get result
      ::Sass::Engine.new(content, options).render
    end

  end
end
