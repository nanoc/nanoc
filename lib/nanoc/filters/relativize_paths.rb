# encoding: utf-8

module Nanoc::Filters
  class RelativizePaths < Nanoc::Filter

    require 'nanoc/helpers/link_to'
    include Nanoc::Helpers::LinkTo

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
      # FIXME use nokogiri or csspool instead of regular expressions
      case params[:type]
      when :html
        content.gsub(/(<[^>]+\s+(src|href))=(['"]?)(\/.*?)\3([\s\/>])/) do
          $1 + '=' + $3 + relative_path_to($4) + $3 + $5
        end
      when :css
        content.gsub(/url\((['"]?)(\/.*?)\1\)/) do
          'url(' + $1 + relative_path_to($2) + $1 + ')'
        end
      when :xml
        selectors = params[:select] || ['//a/@href | a/@href', '//img/@src | img/@src', '//script/@src | script/@src', '//link/@href | link/@href']
        namespaces = params[:namespaces] || {}
        nokogiri_process(content, selectors, namespaces, params[:type])
      when :xhtml
        selectors = params[:select] || ['//a/@href | a/@href', '//img/@src | img/@src', '//script/@src | script/@src', '//link/@href | link/@href']
        namespaces = params[:namespaces] || {}
        nokogiri_process(content, selectors, namespaces, params[:type])
      else
        raise RuntimeError.new(
          "The relativize_paths needs to know the type of content to " +
          "process. Pass :type => :xml for XML, :type => :html for HTML or :type => :css for CSS."
        )
      end
    end
    
    private
    
    def nokogiri_process(content, selectors, namespaces, type)
      require 'nokogiri'
      # Because it's a DocumentFragment all XPath expressions that begins 
      # with '//' should be changed to '*//'.
      # Consider converting `//([^\s\[]+(\[[^\]]+])?)` in
      # something like `*//\1 | \1` to make some magic with partial content.
      selectors.map! { |s| s.sub(%r{^(//)}, '*\1') }
      # Ensure that all prefixes are String
      namespaces = namespaces.inject({}) { |new, (prefix, uri)| new.merge(prefix.to_s => uri) }
      doc = ::Nokogiri::XML.fragment(content)
      selectors.each do |selector|
        doc.xpath(selector, namespaces).each do |node|
          node.content = relative_path_to(node.content)
        end
      end
      # Because using the `Nokogiri::XML::DocumentFragment` class DOCTYPE 
      # pseudonodes becomes even more creepy than usual.
      doc.method("to_#{type}").call.sub(/(!DOCTYPE.+?)(&gt;)/, '<\1>')
    end
    
    
  end
end