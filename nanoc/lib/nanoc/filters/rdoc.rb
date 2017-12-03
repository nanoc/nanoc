# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class RDoc < Nanoc::Filter
    identifier :rdoc

    requires 'rdoc'

    # Runs the content through [RDoc::Markup](http://docs.seattlerb.org/rdoc/RDoc/Markup.html).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      options = ::RDoc::Options.new
      to_html = ::RDoc::Markup::ToHtml.new(options)
      ::RDoc::Markup.new.convert(content, to_html)
    end
  end
end
