module Nanoc

  # A Nanoc::Router is an abstract superclass that determines the paths of
  # page representations, both the path on the disk (relative to the site's
  # output directory) and the path as it appears on the web site.
  class Router < Plugin

    # Creates a new router for the given site.
    def initialize(site)
      @site = site
    end

    # Returns the routed path for the given page representation, including the
    # filename and the extension. It should start with a slash, and and should
    # be relative to the web root (i.e. should not include any references to
    # the output directory). There is no need to let this method handle custom
    # paths.
    #
    # Subclasses must implement this method.
    def path_for(page_rep)
      raise NotImplementedError.new("Nanoc::Router subclasses must implement #path_for.")
    end

    # Returns the web path for the given page representation, i.e. the page
    # rep's custom path or routed path with index filenames stripped.
    def web_path_for(page_rep)
      # Get actual path
      path =   nil
      path ||= page_rep.attributes[:custom_path]
      path ||= page_rep.page.attribute_named(:custom_path) if page_rep.name == :default
      path ||= path_for(page_rep)

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

    # Returns the disk path for the given page representation, i.e. the page's
    # custom path or routed path relative to the output directory.
    def disk_path_for(page_rep)
      @site.config[:output_dir] + (
        page_rep.attribute_named(:custom_path) ||
        path_for(page_rep)
      )
    end

  end

end
