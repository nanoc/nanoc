module Nanoc::Filters
  # @api private
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

      if document.warnings.length != 0
        $stderr.puts "kramdown warning(s) for #{@item_rep.inspect}"
        document.warnings.each do |warning|
          $stderr.puts "  #{warning}"
        end
      end

      document.to_html
    end
  end
end
