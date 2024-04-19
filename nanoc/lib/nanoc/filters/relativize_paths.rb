# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class RelativizePaths < Nanoc::Filter
    identifier :relativize_paths

    require 'nanoc/helpers/link_to'
    include Nanoc::Helpers::LinkTo

    prepend MemoWise

    SELECTORS =
      [
        '*/@href',
        '*/@src',
        'object/@data',
        'video/@poster',
        'param[@name="movie"]/@value',
        'form/@action',
        'comment()',
        { path: '*/@srcset', type: :srcset },
      ].freeze

    GCSE_SEARCH_WORKAROUND = 'nanoc__gcse_search__f7ac3462f628a053f86fe6563c0ec98f1fe45cee'

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
    def run(content, params = {})
      # Set assigns so helper function can be used
      @item_rep = assigns[:item_rep] if @item_rep.nil?

      # Filter
      case params[:type]
      when :css
        relativize_css(content, params)
      when :html, :html5, :xml, :xhtml
        relativize_html_like(content, params)
      else
        raise 'The relativize_paths needs to know the type of content to ' \
          'process. Pass a :type to the filter call (:html for HTML, ' \
          ':xhtml for XHTML, :xml for XML, or :css for CSS).'
      end
    end

    protected

    def relativize_css(content, params)
      # FIXME: parse CSS the proper way using csspool or something
      content.gsub(/url\((['"]?)(\/(?:[^\/].*?)?)\1\)/) do
        quote = Regexp.last_match[1]
        path = Regexp.last_match[2]

        if exclude?(path, params)
          Regexp.last_match[0]
        else
          'url(' + quote + relative_path_to(path) + quote + ')'
        end
      end
    end

    def excludes(params)
      raw = [params.fetch(:exclude, [])].flatten
      raw.map do |exclusion|
        case exclusion
        when Regexp
          exclusion
        when String
          /\A#{exclusion}(\z|\/)/
        end
      end
    end
    memo_wise :excludes

    def exclude?(path, params)
      # TODO: Use #match? on newer Ruby versions
      excludes(params).any? { |ex| path =~ ex }
    end

    def relativize_html_like(content, params)
      selectors             = params.fetch(:select, SELECTORS)
      namespaces            = params.fetch(:namespaces, {})
      type                  = params.fetch(:type)
      nokogiri_save_options = params.fetch(:nokogiri_save_options, nil)

      parser = parser_for(type)
      content = fix_content(content, type)

      nokogiri_process(content, selectors, namespaces, parser, type, nokogiri_save_options, params)
    end

    def parser_for(type)
      case type
      when :html
        require 'nokogiri'
        ::Nokogiri::HTML
      when :html5
        require 'nokogiri'
        ::Nokogiri::HTML5
      when :xml
        require 'nokogiri'
        ::Nokogiri::XML
      when :xhtml
        require 'nokogiri'
        ::Nokogiri::XML
      end
    end

    def fix_content(content, type)
      case type
      when :xhtml
        # FIXME: cleanup because it is ugly
        # this cleans the XHTML namespace to process fragments and full
        # documents in the same way. At least, Nokogiri adds this namespace
        # if detects the `html` element.
        content.sub(%r{(<html[^>]+)xmlns="http://www.w3.org/1999/xhtml"}, '\1')
      else
        content
      end
    end

    def nokogiri_process(content, selectors, namespaces, klass, type, nokogiri_save_options, params)
      # Ensure that all prefixes are strings
      namespaces = namespaces.reduce({}) { |new, (prefix, uri)| new.merge(prefix.to_s => uri) }

      content = apply_gcse_search_workaround(content)

      doc = /<html[\s>]/.match?(content) ? klass.parse(content) : klass.fragment(content)
      handle_selectors(selectors, doc, namespaces, klass, type, params)

      output =
        case type
        when :html5
          doc.to_html(save_with: nokogiri_save_options)
        else
          doc.send("to_#{type}", save_with: nokogiri_save_options)
        end

      revert_gcse_search_workaround(output)
    end

    def apply_gcse_search_workaround(content)
      content.gsub('gcse:search', GCSE_SEARCH_WORKAROUND)
    end

    def revert_gcse_search_workaround(content)
      content.gsub(GCSE_SEARCH_WORKAROUND, 'gcse:search')
    end

    def handle_selectors(selectors, doc, namespaces, klass, type, params)
      selectors_by_type(selectors).each do |selector_type, sub_selectors|
        selector = sub_selectors.map { |sel| "descendant-or-self::#{sel.fetch(:path)}" }.join('|')

        doc.xpath(selector, namespaces).each do |node|
          if node.name == 'comment'
            nokogiri_process_comment(node, doc, sub_selectors, namespaces, klass, type, params)
          elsif path_is_relativizable?(node.content, params)
            node.content = relativize_node(node, selector_type)
          end
        end
      end
    end

    def selectors_by_type(selectors)
      typed_selectors =
        selectors.map do |s|
          if s.respond_to?(:keys)
            s
          else
            { path: s, type: :basic }
          end
        end

      typed_selectors.group_by { |s| s.fetch(:type) }
    end

    def nokogiri_process_comment(node, doc, selectors, namespaces, klass, type, params)
      content = node.content.dup.sub(%r{^(\s*\[.+?\]>\s*)(.+?)(\s*<!\[endif\])}m) do |_m|
        beginning = Regexp.last_match[1]
        body = Regexp.last_match[2]
        ending = Regexp.last_match[3]

        beginning + nokogiri_process(body, selectors, namespaces, klass, type, nil, params) + ending
      end

      node.replace(Nokogiri::XML::Comment.new(doc, content))
    end

    def relativize_node(node, selector_type)
      case selector_type
      when :basic
        relative_path_to(node.content)
      when :srcset
        handle_srcset_node(node)
      else
        raise Nanoc::Core::Errors::InternalInconsistency, "Unsupported selector type #{selector_type.inspect} in #{self.class}"
      end
    end

    def handle_srcset_node(node)
      parsed = Nanoc::Extra::SrcsetParser.new(node.content).call

      if parsed.is_a?(Array)
        parsed.map do |pair|
          [relative_path_to(pair[:url]), pair[:rest]].join('')
        end.join(',')
      else
        relative_path_to(parsed)
      end
    end

    def path_is_relativizable?(path, params)
      path.match?(/\A\s*\//) && !exclude?(path, params)
    end
  end
end
