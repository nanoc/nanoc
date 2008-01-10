module Nanoc
  class Filter < Plugin

    def initialize(page, site)
      @page   = page
      @pages  = site.pages.map { |p| p.to_proxy }
      @config = site.config
      @site   = site
    end

    def run(content)
      error 'Filter#run must be overridden'
    end

  end
end
