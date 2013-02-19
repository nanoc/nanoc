# encoding: utf-8

module Nanoc::Filters

  # @since 3.2.0
  class Redcarpet < Nanoc::Filter

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
    #   @option params [Boolean] :with_toc (false) A boolean to request a table
    #     of contents

    #   @return [String] The filtered content
    def run(content, params={})
      if ::Redcarpet::VERSION > '2'
        options          = params[:options]          || {}
        renderer_class   = params[:renderer]         || ::Redcarpet::Render::HTML
        renderer_options = params[:renderer_options] || {}
        with_toc         = params[:with_toc]         || false

        if options.is_a?(Array)
          warn 'WARNING: You are passing an array of options to the :redcarpet filter, but Redcarpet 2.x expects a hash instead. This will likely fail.'
        end

        if with_toc
          raise "Unexpected renderer: #{renderer_class.class}" unless renderer_class <= ::Redcarpet::Render::HTML

          # with_toc implies with_toc_data for the HTML renderer
          renderer_options[:with_toc_data] = true
        end

        renderer = renderer_class.new(renderer_options)

        # check if a table-of-contents is requested
        if with_toc == true
          # to include a TOC, Redcarpet needs two passes:
          # the first pass with the HTML_TOC renderer creates the TOC, its output
          # needs to be joined with the second pass from the HTML renderer
          renderer_toc = ::Redcarpet::Render::HTML_TOC.new()
          toc = ::Redcarpet::Markdown.new(renderer_toc, options).render(content)
          toc + ::Redcarpet::Markdown.new(renderer,     options).render(content)
        else
          ::Redcarpet::Markdown.new(renderer, options).render(content)
        end
      else
        options = params[:options] || []
        ::Redcarpet.new(content, *options).to_html
      end
    end

  end

end
