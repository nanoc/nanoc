# encoding: utf-8

module Nanoc::Filters
  class RelativizePaths < Nanoc::Filter

    require 'nanoc/helpers/link_to'
    include Nanoc::Helpers::LinkTo

    SELECTORS = [ '*/@href', '*/@src', 'object/@data', 'param[@name="movie"]/@content', 'comment()' ]

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
    #   nodes to modify. This param is useful only for the `:html`, `:xml` and
    #   `:xhtml` types.
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
      when :css
        # FIXME parse CSS the proper way using csspool or something
        content.gsub(/url\((['"]?)(\/(?:[^\/].*?)?)\1\)/) do
          'url(' + $1 + relative_path_to($2) + $1 + ')'
        end
      when :html, :xml, :xhtml
        selectors  = params.fetch(:select) { SELECTORS }
        namespaces = params[:namespaces] || {}

        require 'nokogiri'
        case params[:type]
        when :html
          klass = ::Nokogiri::HTML
        when :xml
          klass = ::Nokogiri::XML
        when :xhtml
          klass = ::Nokogiri::XML
          # FIXME cleanup because it is ugly
          # this cleans the XHTML namespace to process fragments and full
          # documents in the same way. At least, Nokogiri adds this namespace
          # if detects the `html` element.
          content = content.sub(%r{(<html[^>]+)xmlns="http://www.w3.org/1999/xhtml"}, '\1')
        end

        nokogiri_process(content, selectors, namespaces, klass, params[:type])
      else
        raise RuntimeError.new(
          "The relativize_paths needs to know the type of content to " +
          "process. Pass a :type to the filter call (:html for HTML, " +
          ":xhtml for XHTML, :xml for XML, or :css for CSS).")
      end
    end

  protected

    def nokogiri_process(content, selectors, namespaces, klass, type)
      # Ensure that all prefixes are strings
      namespaces = namespaces.inject({}) { |new, (prefix, uri)| new.merge(prefix.to_s => uri) }

      doc = content =~ /<html[\s>]/ ? klass.parse(content) : klass.fragment(content)
      selectors.map { |sel| "descendant-or-self::#{sel}" }.each do |selector|
        doc.xpath(selector, namespaces).each do |node|
          if node.name == 'comment'
            content = node.content.dup
            content = content.sub(%r{^(\s*\[.+?\]>\s*)(.+?)(\s*<!\[endif\])}m) do |m|
              fragment = nokogiri_process($2, selectors, namespaces, klass, type)
              $1 + fragment + $3
            end
            comment = Nokogiri::XML::Comment.new(doc, content)
            # Works w/ Nokogiri 1.5.5 but fails w/ Nokogiri 1.5.2
            node.replace(comment)
          elsif self.path_is_relativizable?(node.content)
            node.content = relative_path_to(node.content)
          end
        end
      end
      result = doc.send("to_#{type}")

      # FIXME cleanup because it is ugly
      # # Because using the `Nokogiri::XML::DocumentFragment` class DOCTYPE 
      # pseudonodes becomes even more creepy than usual.
      result.sub!(/(!DOCTYPE.+?)(&gt;)/, '<\1>')

      result
    end

    def path_is_relativizable?(s)
      s[0,1] == '/'
    end

  end
end

