# encoding: utf-8

module Nanoc3::Filters
  class Less < Nanoc3::Filter

    # Runs the content through [LESS](http://lesscss.org/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'less'

      # Add filename to load path
      $LESS_LOAD_PATH << File.dirname(@item[:content_filename])

      ::Less::Engine.new(content).to_css
    ensure
      # Restore load path
      $LESS_LOAD_PATH.delete_at(-1)
    end

  end
end
