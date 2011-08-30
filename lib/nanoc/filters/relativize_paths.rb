# encoding: utf-8

module Nanoc::Filters
  class RelativizePaths < Nanoc::Filter

    require 'nanoc/helpers/link_to'
    include Nanoc::Helpers::LinkTo

    SELECTORS = [ 'a/@href', 'img/@src', 'script/@src', 'link/@href' ]

    # Relativizes all paths in the given content, which can be HTML, XHTML, XML
    # or CSS. This filter is quite useful if a site needs to be hosted in a
    # subdirectory instead of a subdomain. In HTML, all `href` and `src`
    # attributes will be relativized. In CSS, all `url()` references will be
    # relativized.
    #
    # @param [String] content The content to filter
    #
    # @option params [Symbol] :type The type of content to filter; can be
    #   `:html`, `:xhtml`, `:xml` or `:css`.
    #
    # @option params [Array] :select The XPath expressions that matches the
    #   nodes to modify. This param is useful only for the `:xml` and `:xhtml`
    #   types.
    #
    # @option params [Hash] :namespaces The pairs `prefix => uri` to define
    #   any namespace you want to use in the XPath expressions. This param 
    #   is useful only for the `:xml` and `:xhtml` types.
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Set assigns so helper function can be used
      @item_rep = assigns[:item_rep] if @item_rep.nil?

      # Filter
      case params[:type]
      when :html
        # FIXME parse HTML the proper way using nokogiri
        content.gsub(/(<[^>]+\s+(src|href))=(['"]?)(\/(?:[^\/].*?)?)\3([\s\/>])/) do
          $1 + '=' + $3 + relative_path_to($4) + $3 + $5
        end
      when :css
        # FIXME parse CSS the proper way using csspool or something
        content.gsub(/url\((['"]?)(\/(?:[^\/].*?)?)\1\)/) do
          'url(' + $1 + relative_path_to($2) + $1 + ')'
        end
      when :xml, :xhtml
        selectors  = params.fetch(:select) { SELECTORS }
        namespaces = params[:namespaces] || {}

        if params[:type] == :xhtml
          # FIXME cleanup because it is ugly
          # this cleans the XHTML namespace to process fragments and full
          # documents in the same way. At least, Nokogiri adds this namespace
          # if detects the `html` element.
          content.sub!(%r{(<html[^>]+)xmlns="http://www.w3.org/1999/xhtml"}, '\1')
        end

        nokogiri_process(content, selectors, namespaces, params[:type])
      else
        raise RuntimeError.new(
          "The relativize_paths needs to know the type of content to " +
          "process. Pass a :type to the filter call (:html for HTML, " +
          ":xhtml for XHTML, :xml for XML, or :css for CSS).")
      end
    end

  private

    def nokogiri_process(content, selectors, namespaces, type)
      require 'nokogiri'

      # Ensure that all prefixes are strings
      namespaces = namespaces.inject({}) { |new, (prefix, uri)| new.merge(prefix.to_s => uri) }

      doc = ::Nokogiri::XML.fragment(content)
      selectors.map { |sel| "descendant-or-self::#{sel}" }.each do |selector|
        doc.xpath(selector, namespaces).each do |node|
          node.content = relative_path_to(node.content)
        end
      end
      result = doc.send("to_#{type}")

      # FIXME cleanup because it is ugly
      # Because using the `Nokogiri::XML::DocumentFragment` class DOCTYPE 
      # pseudonodes becomes even more creepy than usual.
      result.sub!(/(!DOCTYPE.+?)(&gt;)/, '<\1>')

      result
    end
    
    
  end
end