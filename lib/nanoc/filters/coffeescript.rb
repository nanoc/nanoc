# encoding: utf-8

module Nanoc::Filters

  # @since 3.3.0
  class CoffeeScript < Nanoc::Filter

    requires 'coffee-script'

    # Runs the content through [CoffeeScript](http://coffeescript.org/).
    # This method takes no options.
    #
    # @param [String] content The CoffeeScript content to turn into JavaScript
    #
    # @return [String] The resulting JavaScript
    def run(content, params = {})
      ::CoffeeScript.compile(content)
    end

  end

end
