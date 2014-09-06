# encoding: utf-8

module Nanoc::Filters
  class TypoHero < Nanoc::Filter
    requires 'typohero'

    # Runs the content through [TypoHero](http://github.com/minad/typohero/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      ::TypoHero.enhance(content)
    end
  end
end
