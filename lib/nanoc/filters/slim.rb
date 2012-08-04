# encoding: utf-8

require 'slim'

module Nanoc::Filters

  # @since 3.2.0
  class Slim < Nanoc::Filter

    # Runs the content through [Slim](http://slim-lang.com/)
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      params = {
        :disable_capture => true,      # Capture managed by nanoc
        :buffer          => '_erbout', # Force slim to output to the buffer used by nanoc
      }.merge params

      # Create context
      context = ::Nanoc::Context.new(assigns)

      ::Slim::Template.new(params) { content }.render(context) { assigns[:content] }
    end

  end

end
