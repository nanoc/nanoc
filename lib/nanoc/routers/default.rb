module Nanoc::Routers

  # The default router organises pages in the most obvious, but sometimes
  # slightly restrictive, way: the hierarchy of compiled pages and assets is
  # the same as the hierarchy of uncompiled pages and assets.
  class Default < Nanoc::Router

    identifier :default

    def path_for_page_rep(page_rep)
      # Get data we need
      filename   = page_rep.attribute_named(:filename)  || 'index'
      extension  = page_rep.attribute_named(:extension) || 'html'

      # Initialize path
      path = page_rep.page.path + filename

      # Add rep name if necessary
      unless page_rep.name == :default
        path += '-' + page_rep.name.to_s
      end

      # Add extension
      path += '.' + extension

      # Done
      path
    end

    def path_for_asset_rep(asset_rep)
      # Get data we need
      extension     = asset_rep.attribute_named(:extension)
      modified_path = asset_rep.asset.path[0..-2]

      # Initialize path
      assets_prefix = @site.config[:assets_prefix] || '/assets'
      path = assets_prefix + modified_path

      # Add rep name if necessary
      unless asset_rep.name == :default
        path += '-' + asset_rep.name.to_s
      end

      # Add extension
      path += '.' + extension

      # Done
      path
    end

  end

end
