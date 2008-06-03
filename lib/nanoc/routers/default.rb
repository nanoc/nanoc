module Nanoc::Routers

  # The default router organises pages in the most obvious, but sometimes
  # slightly restrictive, way: the hierarchy of compiled pages is the same as
  # the hierarchy of uncompiled pages.
  class Default < Nanoc::Router

    identifier :default

    def path_for(page)
      # Get data we need
      filename   = page.attribute_named(:filename)
      extension  = page.attribute_named(:extension)

      # Build path
      page.path + "#{filename}.#{extension}"
    end

  end

end
