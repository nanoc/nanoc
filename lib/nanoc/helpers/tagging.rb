module Nanoc::Helpers

  # Nanoc::Helpers::Tagging provides some support for managing tags added to
  # pages. To add tags to pages, set the +tags+ page attribute to an array of
  # tags that should be applied to the page. For example:
  #
  #   tags: [ 'foo', 'bar', 'baz' ]
  module Tagging

    # Returns a formatted list of tags for the given page as a string. Several
    # parameters allow customization:
    #
    # :base_url:: The URL to which the tag will be appended to construct the
    #             link URL. This URL must have a trailing slash. Defaults to
    #             "http://technorati.com/tag/".
    #
    # :none_text:: The text to display when the page has no tags. Defaults to
    #              "(none)".
    #
    # :separator:: The separator to put between tags. Defaults to ", ".
    def tags_for(page, params={})
      base_url  = params[:base_url]  || 'http://technorati.com/tag/'
      none_text = params[:none_text] || '(none)'
      separator = params[:separator] || ', '

      if page.tags.nil? or page.tags.empty?
        none_text
      else
        page.tags.collect { |tag| link_for_tag(tag, base_url) }.join(separator)
      end
    end

    # Returns all pages with the given tag.
    def pages_with_tag(tag)
      @pages.select { |p| (p.tags || []).include?(tag) }
    end

    # Returns a link to to the specified tag. The link is marked up using the
    # rel-tag microformat.
    #
    # +tag+:: The name of the tag, which should consist of letters and numbers
    #         (no spaces, slashes, or other special characters).
    #
    # +base_url+:: The URL to which the tag will be appended to construct the
    #              link URL. This URL must have a trailing slash.
    def link_for_tag(tag, base_url)
      %[<a href="#{base_url}#{tag}" rel="tag">#{tag}</a>]
    end

  end

end
