# frozen_string_literal: true

module Nanoc::Filters
  class Asciidoctor < Nanoc::Filter
    identifier :asciidoctor

    requires 'asciidoctor'

    def run(content, params = {})
      ::Asciidoctor.render(content, params)
    end
  end
end
