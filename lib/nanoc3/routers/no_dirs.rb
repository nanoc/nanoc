module Nanoc3::Routers

  # The no-directories router organises items very similarly to the default
  # router, but does not create directories unless necessary. This router will
  # therefore generate items with less pretty URLs.
  #
  # For example, a item with path /about/ will be written to /about.html
  # instead of /about/index.html.
  class NoDirs < Nanoc3::Router

    def path_for_item_rep(item_rep)
      # Get data we need
      filename   = item_rep.item[:filename]  || 'index'
      extension  = item_rep.item[:extension] || 'html'

      # Initialize path
      if item_rep.item.identifier == '/'
        path = '/' + filename
      else
        path = item_rep.item.identifier[0..-2]
      end

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
