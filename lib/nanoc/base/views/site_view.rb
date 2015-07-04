module Nanoc
  class SiteView < ::Nanoc::View
    # @api private
    def initialize(site, context)
      super(context)
      @site = site
    end

    # @api private
    def unwrap
      @site
    end
  end
end
