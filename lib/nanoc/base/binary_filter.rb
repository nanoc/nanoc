module Nanoc

  # Nanoc::Filter is responsible for filtering binary assets). It is the
  # (abstract) superclass for all binary filters. Subclasses should override
  # the +run+ method.
  class BinaryFilter < Nanoc::Plugin

    # Creates a new binary filter for the given asset and site.
    #
    # +asset_rep+:: A proxy for the asset representation (Nanoc::AssetRep)
    #               that should be compiled by this filter.
    #
    # +asset+:: A proxy for the asset (Nanoc::Asset) for which +asset_rep+ is
    #           the representation.
    #
    # +site+:: The site (Nanoc::Site) this filter belongs to.
    #
    # +other_assigns+:: A hash containing other variables that should be made
    #                   available during filtering.
    def initialize(asset_rep, asset, site, other_assigns={})
      @asset_rep      = asset_rep
      @asset          = asset
      @pages          = site.pages.map   { |p| p.to_proxy }
      @layouts        = site.layouts.map { |l| l.to_proxy }
      @config         = site.config
      @site           = site
      @other_assigns  = other_assigns
    end

    # Runs the filter. This method returns a File instance pointing to a new
    # file, containing the filtered content.
    #
    # +file+:: A File instance representing the incoming file that should be
    #          filtered. This file should _not_ be modified.
    #
    # Subclasses must implement this method.
    def run(file)
      raise NotImplementedError.new("Nanoc::BinaryFilter subclasses must implement #run")
    end

  end

end
