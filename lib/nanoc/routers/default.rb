module Nanoc::Routers

  # The default router organises pages in the most obvious, but sometimes
  # slightly restrictive, way: the hierarchy of compiled pages is the same as
  # the hierarchy of uncompiled pages.
  class Default < Nanoc::Router

    identifier :default

    # Returns the disk page for the path. This is simply the page's path as
    # stored by the data source, followed by the filename and extension.
    def disk_path_for(page)
      # Get data we need
      filename   = page.attribute_named(:filename)
      extension  = page.attribute_named(:extension)

      # Build path
      page.path + "#{filename}.#{extension}"
    end

    # Returns the web path for the page. This is simply the page's path as it
    # is stored, i.e. the default router simply make sure that the page
    # hierarchy of uncompiled pages is the same as that of compiled pages
    # (unless a custom path is specified).
    def web_path_for(page)
      # Return normal page path
      page.path
    end

  end

end
