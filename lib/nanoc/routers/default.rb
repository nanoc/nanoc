module Nanoc::Routers

  # TODO document
  class Default < Nanoc::Router

    identifier :default

    # TODO document
    def disk_path_for(page)
      # Get data we need
      filename   = page.attribute_named(:filename)
      extension  = page.attribute_named(:extension)

      # Build path
      page.path + "#{filename}.#{extension}"
    end

    # TODO document
    def web_path_for(page)
      # Return normal page path
      page.path
    end

  end

end
