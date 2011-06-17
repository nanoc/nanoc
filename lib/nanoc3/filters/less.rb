# encoding: utf-8

require 'less'

module Nanoc3::Filters
  class Less < Nanoc3::Filter

    # Runs the content through [LESS](http://lesscss.org/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Add filename to load path
      paths = [ File.dirname(@item[:content_filename]) ]
      parser = ::Less::Parser.new(:paths => paths)
      parser.parse(content).to_css
    end

  end
end
