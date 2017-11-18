# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Redcarpet < Nanoc::Filter
    identifier :redcarpet

    requires 'redcarpet'

    def run(content, params = {})
      options          = params.fetch(:options,          {})
      renderer_class   = params.fetch(:renderer,         ::Redcarpet::Render::HTML)
      renderer_options = params.fetch(:renderer_options, {})
      with_toc         = params.fetch(:with_toc,         false)

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
