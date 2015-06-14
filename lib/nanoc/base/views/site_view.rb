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
  end
end
