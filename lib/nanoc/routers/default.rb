module Nanoc::Routers

  # TODO document
  class DefaultRouter < Nanoc::Router

    identifier :default

    # TODO document
    def disk_path_for(page)
      if page.attribute_named(:custom_path).nil?
        # Get data we need
        filename   = page.attribute_named(:filename)
        extension  = page.attribute_named(:extension)

        page.path + "#{filename}.#{extension}"
      else
        page.attribute_named(:custom_path)
      end
    end

    # TODO document
    def web_path_for(page)
      page.attribute_named(:custom_path) || page.path
    end

  end

end
