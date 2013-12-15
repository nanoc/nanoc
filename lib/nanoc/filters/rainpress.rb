# encoding: utf-8

module Nanoc::Filters
  class Rainpress < Nanoc::Filter

    requires 'rainpress'

    # Runs the content through [Rainpress](http://code.google.com/p/rainpress/).
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
