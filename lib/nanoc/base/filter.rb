module Nanoc

  # Nanoc::Filter is responsible for filtering pages. It is the (abstract)
  # superclass for all filters. Subclasses should override the +run+ method.
  class Filter < Plugin

    # Creates a new filter for the given page and site.
    def initialize(page, site, other_assigns={})
      @page          = page
      @pages         = site.pages.map { |p| p.to_proxy }
      @config        = site.config
      @site          = site
      @other_assigns = other_assigns
    end

    # Runs the filter. Subclasses should override this method. This method
    # returns the filtered content.
    def run(content)
      error 'Filter#run must be overridden'
    end

  end

end
