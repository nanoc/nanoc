# encoding: utf-8

module Nanoc3::Helpers

  # Nanoc3::Helpers::Tagging provides some support for managing tags added to
  # items. To add tags to items, set the +tags+ attribute to an array of
  # tags that should be applied to the item. For example:
  #
  #   tags: [ 'foo', 'bar', 'baz' ]
  #
  # To activate this helper, +include+ it, like this:
  #
  #   include Nanoc3::Helpers::Tagging
  module Tagging

    require 'nanoc3/helpers/html_escape'
    include Nanoc3::Helpers::HTMLEscape

    # Returns a formatted list of tags for the given item as a string. The
    # tags will be linked using the `link_for_tag` function; the HTML-escaping
    # rules for this function apply here as well. Several parameters allow
    # customization:
    #
    # :base_url:: The URL to which the tag will be appended to construct the
    #             link URL. This URL must have a trailing slash. Defaults to
    #             "http://technorati.com/tag/".
    #
    # :none_text:: The text to display when the item has no tags. Defaults to
    #              "(none)".
    #
    # :separator:: The separator to put between tags. Defaults to ", ".
    def tags_for(item, params={})
      base_url  = params[:base_url]  || 'http://technorati.com/tag/'
      none_text = params[:none_text] || '(none)'
      separator = params[:separator] || ', '

      if item[:tags].nil? or item[:tags].empty?
        none_text
      else
        item[:tags].map { |tag| link_for_tag(tag, base_url) }.join(separator)
      end
    end

    # Returns all items with the given tag.
    def items_with_tag(tag)
      @items.select { |i| (i[:tags] || []).include?(tag) }
    end

    # Returns a link to to the specified tag. The link is marked up using the
    # rel-tag microformat. The `href` attribute of the link will be HTML-
    # escaped, as will the content of the `a` element.
    #
    # +tag+:: The name of the tag, which should consist of letters and numbers
    #         (no spaces, slashes, or other special characters).
    #
    # +base_url+:: The URL to which the tag will be appended to construct the
    #              link URL. This URL must have a trailing slash.
    def link_for_tag(tag, base_url)
      %[<a href="#{h base_url}#{h tag}" rel="tag">#{h tag}</a>]
    end

  end

end
