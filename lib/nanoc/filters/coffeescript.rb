require 'coffee-script'

module Nanoc::Filters
  class CoffeeScript < Nanoc::Filter
    identifier :coffeescript

    def run(content, params = {})
      ::CoffeeScript.compile(content)
    end
  end
end
