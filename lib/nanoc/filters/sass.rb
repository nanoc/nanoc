module Nanoc::Filter::Sass
  class SassFilter < Nanoc::Filter

    identifiers :sass

    def run(content)
      nanoc_require 'haml'

      ::Sass::Engine.new(content).render
    end

  end
end
