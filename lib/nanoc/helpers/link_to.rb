module Nanoc::Helpers

  # Nanoc::Helpers::LinkTo contains functions for linking to pages.
  #
  # To activate this helper, +include+ it, like this:
  #
  #   include Nanoc::Helpers::LinkTo
  module LinkTo

    include Nanoc::Helpers::HTMLEscape

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
    #   link_to('Blog', '/blog/')
    #   # => '<a href="/blog/">Blog</a>'
    #
    #   page_rep = @pages.find { |p| p.page_id == 'special' }.reps(:default)
    #   link_to('Special Page', page_rep)
    #   # => '<a href="/special_page/">Special Page</a>'
    #
    #   link_to('Blog', '/blog/', :title => 'My super cool blog')
    #   # => '<a href="/blog/" title="My super cool blog">Blog</a>
    def link_to(text, path_or_rep, attributes={})
      # Find path
      path = path_or_rep.is_a?(String) ? path_or_rep : path_or_rep.path

      # Join attributes
      attributes = attributes.inject('') do |memo, (key, value)|
        memo + key.to_s + '="' + h(value) + '" '
      end

      # Create link
      "<a #{attributes}href=\"#{path}\">#{text}</a>"
    end

    # Creates a HTML link using link_to, except when the linked page is the
    # current one. In this case, a span element with class "active" and with
    # the given text will be returned.
    #
    # Examples:
    #
    #   link_to('Blog', '/blog/')
    #   # => '<a href="/blog/">Blog</a>'
    #
    #   link_to('This Page', @page_rep)
    #   # => '<span class="active">This Page</span>'
    def link_to_unless_current(text, path_or_rep, attributes={})
      # Find path
      path = path_or_rep.is_a?(String) ? path_or_rep : path_or_rep.path

      if @page_rep and @page_rep.path == path
        # Create message
        "<span class=\"active\" title=\"You're here.\">#{text}</span>"
      else
        link_to(text, path_or_rep, attributes)
      end
    end

  end

end
