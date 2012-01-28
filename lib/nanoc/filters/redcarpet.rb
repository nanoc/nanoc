# encoding: utf-8

require 'redcarpet'

module Nanoc::Filters

  # @since 3.2.0
  class Redcarpet < Nanoc::Filter

    # Runs the content through [Redcarpet](https://github.com/tanoku/redcarpet/).
    # This method optionally takes processing options to pass on to Redcarpet.
    #
    # @overload run(content, params={})
    #
    #   For Redcarpet 1.x
    #
    #   @param [String] content The content to filter
    #
    #   @option params [Array] :options ([]) A list of options to pass on to
    #     Redcarpet
    #
    #   @return [String] The filtered content
    #   
    # @overload run(content, params={})
    #
    #   For Redcarpet 2.x
    #
    #   @since 3.2.4
    #
    #   @param [String] content The content to filter
    #
    #   @option params [Hash] :options ({}) A list of options to pass on to
    #     Redcarpet itself (not the renderer)
    #
    #   @option params [::Redcarpet::Render::Base] :renderer
    #     (::Redcarpet::Render::HTML) The class of the renderer to use
    #
    #   @option params [Hash] :renderer_options ({}) A list of options to pass
    #     on to the Redcarpet renderer
    #
    #   @return [String] The filtered content
    def run(content, params={})
      if ::Redcarpet::VERSION > '2'
        options          = params[:options]          || {}
        renderer_class   = params[:renderer]         || ::Redcarpet::Render::HTML
        renderer_options = params[:renderer_options] || {}

        if options.is_a?(Array)
          warn 'WARNING: You are passing an array of options to the :redcarpet filter, but Redcarpet 2.x expects a hash instead. This will likely fail.'
        end

        renderer = renderer_class.new(renderer_options)
        ::Redcarpet::Markdown.new(renderer, options).render(content)
      else
        options = params[:options] || []
        ::Redcarpet.new(content, *options).to_html
      end
    end

  end

end
