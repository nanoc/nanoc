Nanoc.load_file('base', 'plugin.rb')

module Nanoc
  class Filter < Plugin

    def initialize(page, pages, config)
      @page   = page
      @pages  = pages
      @config = config
    end

    def run(content)
      error 'ERROR: Filter#run must be overridden'
    end

  end
end
