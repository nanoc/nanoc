module Nanoc

  class BinaryFilter < Nanoc::Plugin

    # TODO add support for multiple reps
    def initialize(asset, site, other_assigns={})
      @asset          = asset
      @pages          = site.pages.map   { |p| p.to_proxy }
      @layouts        = site.layouts.map { |l| l.to_proxy }
      @config         = site.config
      @site           = site
      @other_assigns  = other_assigns
    end

    def run(file)
      raise NotImplementedError.new("Nanoc::BinaryFilter subclasses must implement #run")
    end

  end

end
