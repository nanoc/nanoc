# encoding: utf-8

begin
  # new RDoc
  require 'rdoc/markup'
  require 'rdoc/markup/to_html'
rescue LoadError
  # old RDoc
  require 'rdoc/markup/simple_markup'
  require 'rdoc/markup/simple_markup/to_html'
end

module Nanoc::Filters
  class RDoc < Nanoc::Filter

    # Runs the content through [RDoc::Markup](http://rdoc.rubyforge.org/RDoc/Markup.html).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      begin
        # new RDoc
        ::RDoc::Markup.new.convert(content, ::RDoc::Markup::ToHtml.new)
      rescue LoadError
        # old RDoc
        ::SM::SimpleMarkup.new.convert(content, ::SM::ToHtml.new)
      end
    end

  end
end
