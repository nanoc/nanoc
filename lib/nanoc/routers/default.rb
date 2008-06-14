module Nanoc::Routers

  # The default router organises pages in the most obvious, but sometimes
  # slightly restrictive, way: the hierarchy of compiled pages and assets is
  # the same as the hierarchy of uncompiled pages and assets.
  class Default < Nanoc::Router

    identifier :default

    def path_for_page_rep(page_rep)
      # Get data we need
      filename   = page_rep.attribute_named(:filename)
      extension  = page_rep.attribute_named(:extension)

      # Build path
      path = page_rep.page.path + filename
      if page_rep.name == :default
        path += '.' + extension
      else
        path += page_rep.name.to_s + '.' + extension
      end

      path
    end

    def path_for_asset_rep(asset_rep)
      # Get data we need
      extension     = asset_rep.attribute_named(:extension)
      modified_path = asset_rep.asset.path[0..-2]

      # Build path
      assets_prefix = @site.config[:assets_prefix] || '/assets'
      path = assets_prefix + modified_path
      if asset_rep.name == :default
        path += '.' + extension
      else
        path += '-' + asset_rep.name.to_s + '.' + extension
      end

      path
    end

  end

end
