# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Redcarpet < Nanoc::Filter
    identifier :redcarpet

    requires 'redcarpet'

    # Runs the content through [Redcarpet](https://github.com/vmg/redcarpet).
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
    #   @option params [Boolean] :with_toc (false) A boolean to request a table
    #     of contents
    #
    #   @return [String] The filtered content
    def run(content, params = {})
      if ::Redcarpet::VERSION > '2'
        options          = params.fetch(:options,          {})
        renderer_class   = params.fetch(:renderer,         ::Redcarpet::Render::HTML)
        renderer_options = params.fetch(:renderer_options, {})
        with_toc         = params.fetch(:with_toc,         false)

        if options.is_a?(Array)
          warn 'WARNING: You are passing an array of options to the :redcarpet filter, but Redcarpet 2.x expects a hash instead. This will likely fail.'
        end

        # Setup TOC
        if with_toc
          unless renderer_class <= ::Redcarpet::Render::HTML
            raise "Unexpected renderer: #{renderer_class}"
          end

          # `with_toc` implies `with_toc_data` for the HTML renderer
          renderer_options[:with_toc_data] = true
        end

        # Create renderer
        renderer =
          if renderer_class == ::Redcarpet::Render::HTML_TOC
            renderer_class.new
          else
            renderer_class.new(renderer_options)
          end

        # Render
        if with_toc
          renderer_toc = ::Redcarpet::Render::HTML_TOC.new
          toc  = ::Redcarpet::Markdown.new(renderer_toc, options).render(content)
          body = ::Redcarpet::Markdown.new(renderer,     options).render(content)
          toc + body
        else
          ::Redcarpet::Markdown.new(renderer, options).render(content)
        end
      end
    end
  end
end
