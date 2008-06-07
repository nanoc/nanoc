module Nanoc::Routers

  # The default router organises pages in the most obvious, but sometimes
  # slightly restrictive, way: the hierarchy of compiled pages is the same as
  # the hierarchy of uncompiled pages.
  class Default < Nanoc::Router

    identifier :default

    def path_for(page_rep)
      # Get data we need
      filename   = page_rep.attribute_named(:filename)
      extension  = page_rep.attribute_named(:extension)

      # Build path
      if page_rep.name == :default
        page_rep.page.path + "#{filename}.#{extension}"
      else
        if filename == Nanoc::Page::DEFAULTS[:filename] and
           extension == Nanoc::Page::DEFAULTS[:extension]
          page_rep.page.path + "#{filename}-#{page_rep.name}.#{extension}"
        else
          page_rep.page.path + "#{filename}.#{extension}"
        end
      end
    end

  end

end
