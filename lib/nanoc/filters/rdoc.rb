# encoding: utf-8

module Nanoc::Filters
  class RDoc < Nanoc::Filter

    requires 'rdoc/markup', 'rdoc/markup/to_html'

    # Runs the content through [RDoc::Markup](http://rdoc.rubyforge.org/RDoc/Markup.html).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      ::RDoc::Markup.new.convert(content, ::RDoc::Markup::ToHtml.new)
    end

  end
end
