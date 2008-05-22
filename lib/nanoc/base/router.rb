module Nanoc

  # A Nanoc::Router is an abstract superclass that determines the paths of
  # pages, both the path on the disk (relative to the site's output directory)
  # and the path as it appears on the web site.
  class Router < Plugin

    # Creates a new router for the given site.
    def initialize(site)
      @site = site
    end

    # Returns the path of the page on the disk, relative to the output
    # directory. It should start with a slash.
    #
    # For example, a page with a path of "/foo/bar/" should return something
    # like "/foo/bar.html" or "/foo/bar/index.html". 
    #
    # Subclasses must override this method.
    def disk_path_for(page)
      raise NotImplementedError.new("Nanoc::Router subclasses must implement #disk_path_for.")
    end

    # Returns the path of the page relative to the web root. It should start
    # with a slash.
    #
    # It is correct to let this method return the disk path, but sometimes not
    # desirable: for example, a trailing "index.html" is usually not
    # necessary.
    #
    # When following the example for disk_path_for, a page with a path of
    # "/foo/bar/" should return something like "/foo/bar.html" or "/foo/bar/".
    #
    # Subclasses must override this method.
    def web_path_for(page)
      raise NotImplementedError.new("Nanoc::Router subclasses must implement #web_path_for.")
    end

  end

end
