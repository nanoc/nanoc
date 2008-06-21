module Nanoc::Extensions

  # Nanoc::Extensions::LinkTo contains functions for linking to pages.
  module LinkTo

    include Nanoc::Extensions::HTMLEscape

    # Creates a HTML link to the given path or page/asset representation, and
    # with the given text.
    #
    # +path_or_rep+:: the URL or path (a String) that should be linked to, or
    #                 the page or asset representation that should be linked
    #                 to.
    #
    # +text+:: the visible link text.
    #
    # +attributes+:: a hash containing HTML attributes that will be added to
    #                the link.
    #
    # Examples:
    #
    #   link_to('/blog/', 'Blog')
    #   # => '<a href="/blog/">Blog</a>'
    #
    #   page_rep = @pages.find { |p| p.page_id == 'special' }.reps(:default)
    #   link_to(page_rep, 'Special Page')
    #   # => '<a href="/special_page/">Special Page</a>'
    #
    #   link_to('/blog/', 'Blog', :title => 'My super cool blog')
    #   # => '<a href="/blog/" title="My super cool blog">Blog</a>
    def link_to(path_or_rep, text, attributes={})
      # Find path
      path = path_or_rep.is_a?(String) ? path_or_rep : path_or_rep.path

      # Join attributes
      attributes = attributes.inject('') do |memo, (key, value)|
        memo + key.to_s + '="' + h(value) + '" '
      end

      # Create link
      "<a #{attributes}href=\"#{path}\">#{h text}</a>"
    end

    # Creates a HTML link using link_to, except when the linked page is the
    # current one. In this case, a span element with class "active" and with
    # the given text will be returned.
    #
    # Examples:
    #
    #   link_to('/blog/', 'Blog')
    #   # => '<a href="/blog/">Blog</a>'
    #
    #   link_to(@page_rep, 'This Page')
    #   # => '<span class="active">This Page</span>'
    def link_to_unless_current(path_or_rep, text, attributes={})
      # Find path
      path = path_or_rep.is_a?(String) ? path_or_rep : path_or_rep.path

      if @page_rep and @page_rep.path == path
        # Create message
        "<span class=\"active\" title=\"You're here.\">#{h text}</span>"
      else
        link_to(path_or_rep, text, attributes)
      end
    end

  end

end
