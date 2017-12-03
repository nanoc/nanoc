# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class CoffeeScript < Nanoc::Filter
    identifier :coffeescript

    requires 'coffee-script'

    # Runs the content through [CoffeeScript](http://coffeescript.org/).
    # This method takes no options.
    #
    # @param [String] content The CoffeeScript content to turn into JavaScript
    #
    # @return [String] The resulting JavaScript
    def run(content, _params = {})
      ::CoffeeScript.compile(content)
    end
  end
end
