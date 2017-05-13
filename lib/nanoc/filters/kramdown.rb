# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Kramdown < Nanoc::Filter
    identifier :kramdown

    requires 'kramdown'

    # Runs the content through [Kramdown](http://kramdown.gettalong.org/).
    # Parameters passed to this filter will be passed on to Kramdown.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      params = params.dup
      warning_filters = params.delete(:warning_filters)
      document = ::Kramdown::Document.new(content, params)

      if warning_filters
        r = Regexp.union(warning_filters)
        warnings = document.warnings.reject { |warning| r =~ warning }
      else
        warnings = document.warnings
      end

      if warnings.any?
        $stderr.puts "kramdown warning(s) for #{@item_rep.inspect}"
        warnings.each do |warning|
          $stderr.puts "  #{warning}"
        end
      end

      document.to_html
    end
  end
end
