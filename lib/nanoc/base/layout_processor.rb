Nanoc.load_file('base', 'plugin.rb')

module Nanoc
  class LayoutProcessor < Plugin

    def initialize(page, pages, config, site)
      @page   = page
      @pages  = pages
      @config = config
      @site   = site
    end

    def run(layout)
      error 'LayoutProcessor#run must be overridden'
    end

    # Extensions

    class << self
      attr_accessor :_extensions
    end

    def self.extensions(*extensions)
      extensions.empty? ? self._extensions || [] : self._extensions = (self._extensions || []) + extensions
    end

    def self.extension(extension=nil)
      extension.nil? ? self.extensions.first : self.extensions(extension)
    end

  end
end
