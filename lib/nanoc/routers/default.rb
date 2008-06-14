module Nanoc::Routers

  # The default router organises pages in the most obvious, but sometimes
  # slightly restrictive, way: the hierarchy of compiled pages is the same as
  # the hierarchy of uncompiled pages.
  class Default < Nanoc::Router

    identifier :default

    def path_for_page_rep(page_rep)
      # Get data we need
      filename   = page_rep.attribute_named(:filename)
      extension  = page_rep.attribute_named(:extension)

      # Build path
      if page_rep.name == :default
        page_rep.page.path + "#{filename}.#{extension}"
      else
        page_rep.page.path + "#{filename}-#{page_rep.name}.#{extension}"
      end
    end

    def path_for_asset_rep(asset_rep)
      # Get data we need
      extension     = asset_rep.attribute_named(:extension)
      modified_path = asset_rep.asset.path[0..-2]

      # Build path
      if asset_rep.name == :default
        modified_path + '.' + extension
      else
        modified_path + '-' + asset_rep.name.to_s + '.' + extension
      end
    end

  end

end
