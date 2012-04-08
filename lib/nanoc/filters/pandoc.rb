# encoding: utf-8

require 'pandoc-ruby'

module Nanoc::Filters
  class Pandoc < Nanoc::Filter

    # Runs the content through [Pandoc](http://johnmacfarlane.net/pandoc/)
    # using [PandocRuby](https://github.com/alphabetum/pandoc-ruby). Options
    # are passed on to PandocRuby.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      PandocRuby.convert(content, params)
    end

  end
end
