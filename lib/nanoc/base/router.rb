module Nanoc

  # TODO turn Router into a Plugin subclass and give it an identifier

  # A router determines the paths of pages, both the path on the disk
  # (relative to the site's output directory) and the path as it appears on
  # the web site.
  class Router

    # Creates a new router for the given site.
    def initialize(site)
      @site = site
    end

    # Returns the path of the page on the disk, relative to the output
    # directory. It should start with a slash.
    def disk_path_for(page)
      if page.attribute_named(:custom_path).nil?
        # Get data we need
        filename   = page.attribute_named(:filename)
        extension  = page.attribute_named(:extension)

        "#{page.path}#{filename}.#{extension}"
      else
        "#{page.path}"
      end
    end

    # Returns the path of the page relative to the web root. It should start
    # with a slash.
    def web_path_for(page)
      page.path
    end

  end

end
