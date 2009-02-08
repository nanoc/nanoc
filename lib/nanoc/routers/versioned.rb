module Nanoc::Routers

  # The versioned router behaves pretty much like the default router, with the
  # exception that asset representations (but not page representations) can
  # have versions which will be added to generated URLs.
  #
  # This is very useful if you want to cache assets aggressively by sending an
  # +Expires+ header to clients. An +Expires+ header usually has the issue
  # that clients will not request the asset even if it has changed; giving the
  # asset a different version will cause the URL to be changed, which in turn
  # will cause the client to request the new asset.
  #
  # = Example
  #
  # For example, the URL of a textual asset containing the CSS stylesheet with
  # its 'version' attribute set to 28 will become /assets/style-v28.css.
  #
  # To link to the stylesheet in a DRY way,
  # give the asset a unique name (such as 'style') and then do something along
  # this way:
  #
  #   <link rel="stylesheet"
  #         type="text/css"
  #         media="screen"
  #         href="<%= @assets.find { |a| a.asset_id == 'style' }.path %>">
  class Versioned < Nanoc::Router

    identifier :versioned

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
