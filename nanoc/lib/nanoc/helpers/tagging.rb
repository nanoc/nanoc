# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#tagging
  module Tagging
    require 'nanoc/helpers/html_escape'
    include Nanoc::Helpers::HTMLEscape

    # @param [String] base_url
    # @param [String] none_text
    # @param [String] separator
    #
    # @return [String]
    def tags_for(item, base_url: nil, none_text: '(none)', separator: ', ')
      if item[:tags].nil? || item[:tags].empty?
        none_text
      else
        item[:tags].map { |tag| base_url ? link_for_tag(tag, base_url) : tag }.join(separator)
      end
    end

    # @param [String] tag
    #
    # @return [Array]
    def items_with_tag(tag)
      @items.select { |i| (i[:tags] || []).include?(tag) }
    end

    # @param [String] tag
    # @param [String] base_url
    #
    # @return [String]
    def link_for_tag(tag, base_url)
      %(<a href="#{h base_url}#{h tag}" rel="tag">#{h tag}</a>)
    end
  end
end
