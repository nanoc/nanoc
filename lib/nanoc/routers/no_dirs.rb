module Nanoc::Routers

  # The no-directories router organises pages very similarly to the default
  # router, but does not create directories unless necessary. This router will
  # therefore generate pages with less pretty URLs.
  #
  # For example, a page with path /about/ will be written to /about.html
  # instead of /about/index.html.
  class NoDirs < Nanoc::Router

    identifier :no_dirs

    def path_for_page_rep(page_rep)
      # Get data we need
      filename   = page_rep.attribute_named(:filename)
      extension  = page_rep.attribute_named(:extension)

      # Initialize path
      if page_rep.page.path == '/'
        path = '/' + filename
      else
        path = page_rep.page.path[0..-2]
      end

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
      version       = asset_rep.attribute_named(:version)

      # Initialize path
      assets_prefix = @site.config[:assets_prefix] || '/assets'
      path = assets_prefix + modified_path

      # Add version if necessary
      unless version.nil?
        path += '-v' + version.to_s
      end

      # Add rep name
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
