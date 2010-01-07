# encoding: utf-8

module Nanoc3::Helpers

  # Nanoc3::Helpers::LinkTo contains functions for linking to items.
  #
  # To activate this helper, +include+ it, like this:
  #
  #   include Nanoc3::Helpers::LinkTo
  module LinkTo

    require 'nanoc3/helpers/html_escape'
    include Nanoc3::Helpers::HTMLEscape

    # Creates a HTML link to the given path or item representation, and with
    # the given text.
    #
    # +path_or_rep+:: the URL or path (a String) that should be linked to, or
    #                 the item representation that should be linked to.
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
    #   item_rep = @items.find { |i| i.item_id == 'special' }.reps[0]
    #   link_to('Special Item', item_rep)
    #   # => '<a href="/special_item/">Special Item</a>'
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
      "<a #{attributes}href=\"#{h path}\">#{text}</a>"
    end

    # Creates a HTML link using link_to, except when the linked item is the
    # current one. In this case, a span element with class "active" and with
    # the given text will be returned.
    #
    # Examples:
    #
    #   link_to_unless_current('Blog', '/blog/')
    #   # => '<a href="/blog/">Blog</a>'
    #
    #   link_to_unless_current('This Item', @item_rep)
    #   # => '<span class="active">This Item</span>'
    def link_to_unless_current(text, path_or_rep, attributes={})
      # Find path
      path = path_or_rep.is_a?(String) ? path_or_rep : path_or_rep.path

      if @item_rep and @item_rep.path == path
        # Create message
        "<span class=\"active\" title=\"You're here.\">#{text}</span>"
      else
        link_to(text, path_or_rep, attributes)
      end
    end

    # Returns the relative path from the current item to the given path or
    # item representation.
    #
    # +path_or_rep+:: the URL or path (a String) to where the relative should
    #                 point, or the item representation to which the relative
    #                 should point.
    #
    # Example:
    #
    #   # if the current item's path is /foo/bar/
    #   relative_path('/foo/qux/')
    #   # => '../qux/'
    def relative_path_to(target)
      require 'pathname'

      # Find path
      if target.is_a?(String)
        path = target
      elsif target.respond_to?(:rep)
        path = target.rep(:default).path
      else
        path = target.path
      end

      # Get source and destination paths
      dst_path   = Pathname.new(path)
      src_path   = Pathname.new(@item_rep.path)

      # Calculate elative path (method depends on whether destination is a
      # directory or not).
      if src_path.to_s[-1,1] != '/'
        relative_path = dst_path.relative_path_from(src_path.dirname).to_s
      else
        relative_path = dst_path.relative_path_from(src_path).to_s
      end

      # Add trailing slash if necessary
      if dst_path.to_s[-1,1] == '/'
        relative_path += '/'
      end

      # Done
      relative_path
    end

  end

end
