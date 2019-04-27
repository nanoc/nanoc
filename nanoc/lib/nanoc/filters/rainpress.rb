# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Rainpress < Nanoc::Filter
    identifier :rainpress

    requires 'rainpress'

    # Runs the content through [Rainpress](https://github.com/ddfreyne/rainpress).
    # Parameters passed to this filter will be passed on to Rainpress.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      ::Rainpress.compress(content, params)
    end
  end
end
