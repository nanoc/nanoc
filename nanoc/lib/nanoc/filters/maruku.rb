# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Maruku < Nanoc::Filter
    identifier :maruku

    requires 'maruku'

    # Runs the content through [Maruku](https://github.com/bhollis/maruku/).
    # Parameters passed to this filter will be passed on to Maruku.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Get result
      ::Maruku.new(content, params).to_html
    end
  end
end
