# encoding: utf-8

module Nanoc::Filters

  class Typogruby < Nanoc::Filter

    identifier :typogruby

    requires 'typogruby'

    # Runs the content through [Typogruby](http://avdgaag.github.com/typogruby/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Get result
      ::Typogruby.improve(content)
    end

  end

end
