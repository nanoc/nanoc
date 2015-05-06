# encoding: utf-8

module Nanoc
  class SiteView
    # @api private
    def initialize(site)
      @site = site
    end

    # @api private
    def unwrap
      @site
    end

    # @api private
    def layouts
      @site.layouts.map { |l| Nanoc::LayoutView.new(l) }
    end

    # @api private
    def captures_store
      @site.captures_store
    end

    # @api private
    def captures_store_compiled_items
      @site.captures_store_compiled_items
    end

    # @api private
    def compiler
      @site.compiler
    end
  end
end
