# encoding: utf-8

module Nanoc::Filters

  class Asciidoctor < Nanoc::Filter

    requires 'asciidoctor'

    # Runs the content through [Asciidoctor](http://asciidoctor.org/).
    # Parameters passed to this filter will be passed on to `Asciidoctor.render`.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      Asciidoctor.render(content, params)
    end

  end

end
