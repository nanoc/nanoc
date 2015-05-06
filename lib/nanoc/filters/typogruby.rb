# encoding: utf-8

module Nanoc::Filters
  # @since 3.2.0
  #
  # @api private
  class Typogruby < Nanoc::Filter
    requires 'typogruby'

    # Runs the content through [Typogruby](http://avdgaag.github.com/typogruby/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      # Get result
      ::Typogruby.improve(content)
    end
  end
end
