module Nanoc

  # Nanoc::Filter is responsible for filtering pages. It is the (abstract)
  # superclass for all filters. Subclasses should override the +run+ method.
  class Filter < Plugin

    # Creates a new filter for the given page and site.
    #
    # +page_rep+:: A proxy for the page representation (Nanoc::PageRep) that
    #              should be compiled by this filter.
    #
    # +page+:: A proxy for the given page representation's page (Nanoc::Page).
    #
    # +site+:: The site (Nanoc::Site) this filter belongs to.
    #
    # +other_assigns+:: A hash containing other variables that should be made
    #                   available during filtering.
    def initialize(page_rep, page, site, other_assigns={})
      @page_rep       = page_rep
      @page           = page
      @pages          = site.pages.map   { |p| p.to_proxy }
      @layouts        = site.layouts.map { |l| l.to_proxy }
      @config         = site.config
      @site           = site
      @other_assigns  = other_assigns
    end

    # Runs the filter. This method returns the filtered content.
    #
    # Subclasses should override this method.
    #
    # +content+:: The unprocessed content that should be filtered.
    def run(content)
      raise NotImplementedError.new("Nanoc::Filter subclasses must implement #run")
    end

    # Returns a hash with data that should be available.
    def assigns
      @other_assigns.merge({
        :page_rep => @page_rep,
        :page     => @page,
        :pages    => @pages,
        :layouts  => @layouts,
        :config   => @config,
        :site     => @site
      })
    end

    class << self

      attr_accessor :extensions # :nodoc:

      def extensions(*exts) # :nodoc:
        @extensions = [] unless instance_variables.include?('@extensions')
        exts.empty? ? @extensions : @extensions = exts
      end

      def extension(ext=nil) # :nodoc:
        @extensions = [] unless instance_variables.include?('@extensions')
        ext.nil? ? @extensions.first : extensions(ext)
      end

    end

  end

end
