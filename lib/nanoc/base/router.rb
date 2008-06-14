module Nanoc

  # A Nanoc::Router is an abstract superclass that determines the paths of
  # page and asset representations, both the path on the disk (relative to the
  # site's output directory) and the path as it appears on the web site.
  class Router < Plugin

    # Creates a new router for the given site.
    def initialize(site)
      @site = site
    end

    # Returns the routed path for the given page representation, including the
    # filename and the extension. It should start with a slash, and should be
    # relative to the web root (i.e. should not include any references to the
    # output directory). There is no need to let this method handle custom
    # paths.
    #
    # Subclasses must implement this method.
    def path_for_page_rep(page_rep)
      raise NotImplementedError.new("Nanoc::Router subclasses must implement #path_for_page_rep.")
    end

    # Returns the routed path for the given asset representation, including
    # the filename and the extension. It should start with a slash, and should
    # be relative to the web root (i.e. should not include any references to
    # the output directory). There is no need to let this method handle custom
    # paths.
    #
    # Subclasses must implement this method.
    def path_for_asset_rep(asset_rep)
      raise NotImplementedError.new("Nanoc::Router subclasses must implement #path_for_asset_rep.")
    end

    # Returns the web path for the given page or asset representation, i.e.
    # the page or asset rep's custom path or routed path with index filenames
    # stripped.
    def web_path_for(obj)
      # Get actual path
      path ||= obj.attribute_named(:custom_path)
      if obj.is_a?(Nanoc::PageRep) # Page rep
        path ||= path_for_page_rep(obj)
      else # Asset rep
        path ||= path_for_asset_rep(obj)
      end

      # Try stripping each index filename
      @site.config[:index_filenames].each do |index_filename|
        if path[-index_filename.length..-1] == index_filename
          # Strip and stop
          path = path[0..-index_filename.length-1]
          break
        end
      end

      # Return possibly stripped path
      path
    end

    # Returns the disk path for the given page or asset representation, i.e.
    # the page or asset's custom path or routed path relative to the output
    # directory.
    def disk_path_for(obj)
      @site.config[:output_dir] + (
        obj.attribute_named(:custom_path) ||
        (obj.is_a?(Nanoc::PageRep) ? path_for_page_rep(obj) : path_for_asset_rep(obj))
      )
    end

  end

end
