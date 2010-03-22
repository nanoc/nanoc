# encoding: utf-8

module Nanoc3::Filters
  class Rainpress < Nanoc3::Filter

    # Runs the content through [Rainpress](http://code.google.com/p/rainpress/).
    # Parameters passed to this filter will be passed on to Rainpress.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'rainpress'

      ::Rainpress.compress(content, params)
    end

  end
end
