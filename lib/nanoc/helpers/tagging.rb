module Nanoc::Helpers
  # Provides support for managing tags added to items.
  #
  # To add tags to items, set the `tags` attribute to an array of tags that
  # should be applied to the item.
  #
  # @example Adding tags to an item
  #
  #   tags: [ 'foo', 'bar', 'baz' ]
  module Tagging
    require 'nanoc/helpers/html_escape'
    include Nanoc::Helpers::HTMLEscape

    # Returns a formatted list of tags for the given item as a string. The
    # tags will be linked using the {#link_for_tag} function; the
    # HTML-escaping rules for {#link_for_tag} apply here as well.
    #
    # @param [String] base_url The URL to which the tag will be appended
    #   to construct the link URL. This URL must have a trailing slash. The
    #   function will return a tags string without tag page link if the param
    #   is not provided.
    #
    # @param [String] none_text The text to display when
    #   the item has no tags
    #
    # @param [String] separator The separator to put between tags
    #
    # @return [String] A hyperlinked list of tags for the given item
    def tags_for(item, base_url: nil, none_text: '(none)', separator: ', ')
      if item[:tags].nil? || item[:tags].empty?
        none_text
      else
        item[:tags].map { |tag| base_url ? link_for_tag(tag, base_url) : tag }.join(separator)
      end
    end

    # Find all items with the given tag.
    #
    # @param [String] tag The tag for which to find all items
    #
    # @return [Array] All items with the given tag
    def items_with_tag(tag)
      @items.select { |i| (i[:tags] || []).include?(tag) }
    end

    # Returns a link to to the specified tag. The link is marked up using the
    # rel-tag microformat. The `href` attribute of the link will be HTML-
    # escaped, as will the content of the `a` element.
    #
    # @param [String] tag The name of the tag, which should consist of letters
    #   and numbers (no spaces, slashes, or other special characters).
    #
    # @param [String] base_url The URL to which the tag will be appended to
    #   construct the link URL. This URL must have a trailing slash.
    #
    # @return [String] A link for the given tag and the given base URL
    def link_for_tag(tag, base_url)
      %(<a href="#{h base_url}#{h tag}" rel="tag">#{h tag}</a>)
    end
  end
end
