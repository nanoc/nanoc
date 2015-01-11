# encoding: utf-8

module Nanoc::Filters
  class Kramdown < Nanoc::Filter
    requires 'kramdown'

    # Runs the content through [Kramdown](http://kramdown.gettalong.org/).
    # Parameters passed to this filter will be passed on to Kramdown.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      document = ::Kramdown::Document.new(content, params)

      document.warnings.each do |warning|
        $stderr.puts "kramdown warning: #{warning}"
      end

      document.to_html
    end
  end
end
