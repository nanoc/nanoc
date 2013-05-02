# encoding: utf-8

module Nanoc::Filters
  class RDoc < Nanoc::Filter

    identifier :rdoc

    requires 'rdoc'

    def self.setup
      gem 'rdoc', '~> 4.0'
      super
    end

    # Runs the content through [RDoc::Markup](http://rdoc.rubyforge.org/RDoc/Markup.html).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      options = ::RDoc::Options.new
      to_html = ::RDoc::Markup::ToHtml.new(options)
      ::RDoc::Markup.new.convert(content, to_html)
    end

  end
end
