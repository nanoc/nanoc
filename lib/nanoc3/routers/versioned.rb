module Nanoc3::Routers

  # The versioned router behaves pretty much like the default router, with the
  # exception that item representations can have versions which will be added
  # to generated URLs.
  #
  # This is very useful if you want to cache items aggressively by sending an
  # +Expires+ header to clients. An +Expires+ header usually has the issue
  # that clients will not request the item even if it has changed; giving the
  # item a different version will cause the URL to be changed, which in turn
  # will cause the client to request the new item.
  #
  # = Example
  #
  # For example, the URL of an item containing the CSS stylesheet with its
  # 'version' attribute set to 28 will become /assets/style-v28.css.
  #
  # To link to the stylesheet in a DRY way, give the item a unique name (such
  # as 'style') and then do something along this way:
  #
  #   <link rel="stylesheet"
  #         type="text/css"
  #         media="screen"
  #         href="<%= @items.find { |item| item.item_id == 'style' }.path %>">
  class Versioned < Nanoc3::Router

    def path_for_item_rep(item_rep)
      # Get data we need
      filename  = item_rep.item.attribute_named(:filename)  || 'index'
      extension = item_rep.item.attribute_named(:extension) || 'html'
      version   = item_rep.item.attribute_named(:version)

      # Init path
      path = item_rep.item.identifier + filename

      # Add rep name
      unless item_rep.name == :default
        path << '-' + item_rep.name.to_s
      end

      # Add version if necessary
      if version
        path << '-v' + version.to_s
      end

      # Add extension
      path << '.' + extension

      # Done
      path
    end

  end

end
