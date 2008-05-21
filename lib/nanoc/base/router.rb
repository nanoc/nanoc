module Nanoc

  # A router determines the paths of pages, both the path on the disk
  # (relative to the site's output directory) and the path as it appears on
  # the web site.
  class Router < Plugin

    # Creates a new router for the given site.
    def initialize(site)
      @site = site
    end

    # Returns the path of the page on the disk, relative to the output
    # directory. It should start with a slash.
    def disk_path_for(page)
      raise NotImplementedError.new("Nanoc::Router subclasses must implement #disk_path_for.")
    end

    # Returns the path of the page relative to the web root. It should start
    # with a slash.
    def web_path_for(page)
      raise NotImplementedError.new("Nanoc::Router subclasses must implement #web_path_for.")
    end

  end

end
