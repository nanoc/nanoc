module Nanoc3::Routers

  # The default router organises items in the most obvious, but sometimes
  # slightly restrictive, way: the hierarchy of compiled items is the same as
  # the hierarchy of uncompiled items.
  class Default < Nanoc3::Router

    def path_for_item_rep(item_rep)
      # Get data we need
      filename   = item_rep.item[:filename]  || 'index'
      extension  = item_rep.item[:extension] || 'html'

      # Initialize path
      path = item_rep.item.identifier + filename

      # Add rep name if necessary
      unless item_rep.name == :default
        path += '-' + item_rep.name.to_s
      end

      # Add extension
      path += '.' + extension

      # Done
      path
    end

  end

end
