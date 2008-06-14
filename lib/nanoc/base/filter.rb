module Nanoc

  # Nanoc::Filter is responsible for filtering pages and textual assets
  # (binary assets are filtered using Nanoc::BinaryFilter). It is the
  # (abstract) superclass for all textual filters. Subclasses should override
  # the +run+ method.
  class Filter < Plugin

    # Creates a new filter for the given object (page or asset) and site.
    #
    # +kind+:: The kind of object that is passed. Can be either +:page+ or
    #          +:asset+.
    #
    # +obj_rep+:: A proxy for the page or asset representation (Nanoc::PageRep
    #             or Nanoc::AssetRep) that should be compiled by this filter.
    #
    # +obj+:: A proxy for the page or asset's page (Nanoc::Page or
    #         Nanoc::Asset).
    #
    # +site+:: The site (Nanoc::Site) this filter belongs to.
    #
    # +other_assigns+:: A hash containing other variables that should be made
    #                   available during filtering.
    def initialize(kind, obj_rep, obj, site, other_assigns={})
      if kind == :page
        @page_rep     = obj_rep
        @page         = obj
      else
        @asset_rep    = obj_rep
        @asset        = obj
      end
      @assets         = site.assets.map  { |a| a.to_proxy }
      @pages          = site.pages.map   { |p| p.to_proxy }
      @layouts        = site.layouts.map { |l| l.to_proxy }
      @config         = site.config
      @site           = site
      @other_assigns  = other_assigns
    end

    # Runs the filter. This method returns the filtered content.
    #
    # +content+:: The unprocessed content that should be filtered.
    #
    # Subclasses must implement this method.
    def run(content)
      raise NotImplementedError.new("Nanoc::Filter subclasses must implement #run")
    end

    # Returns a hash with data that should be available.
    def assigns
      @other_assigns.merge({
        :page_rep   => @page_rep,
        :page       => @page,
        :asset_rep  => @asset_rep,
        :asset      => @asset,
        :pages      => @pages,
        :assets     => @assets,
        :layouts    => @layouts,
        :config     => @config,
        :site       => @site
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
