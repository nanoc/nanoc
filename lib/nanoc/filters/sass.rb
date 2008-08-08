module Nanoc::Filters
  class Sass < Nanoc::Filter

    identifiers :sass

    def run(content)
      require 'sass'

      ::Sass::Engine.new(content).render
    end

  end
end
