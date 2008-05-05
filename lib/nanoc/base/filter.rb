module Nanoc

  # Nanoc::Filter is responsible for filtering pages. It is the (abstract)
  # superclass for all filters. Subclasses should override the +run+ method.
  class Filter < Plugin

    # Creates a new filter for the given page and site.
    def initialize(page, site, other_assigns={})
      @page           = page
      @pages          = site.pages.map   { |p| p.to_proxy }
      @layouts        = site.layouts.map { |l| l.to_proxy }
      @config         = site.config
      @site           = site
      @other_assigns  = other_assigns
    end

    # Runs the filter. Subclasses should override this method. This method
    # returns the filtered content.
    def run(content)
      error 'Filter#run must be overridden'
    end

    # Returns a hash with data that should be available.
    def assigns
      @other_assigns.merge({ :page => @page, :pages => @pages, :layouts => @layouts, :config => @config, :site => @site })
    end

    class << self

      attr_accessor :extensions # :nodoc:

      # Sets or returns the extensions for this filter when used as a
      # layout processor.
      # 
      # When given a list of extension symbols, sets the extensions for
      # this layout processor. When given nothing, returns an array of
      # extension symbols.
      def extensions(*exts)
        @extensions = [] unless instance_variables.include?('@extensions')
        exts.empty? ? @extensions : @extensions = exts
      end

      # Sets or returns the extension for this filter when used as a
      # layout processor.
      # 
      # When given an extension symbols, sets the extension for this layout
      # processor. When given nothing, returns the extension.
      def extension(ext=nil)
        @extensions = [] unless instance_variables.include?('@extensions')
        ext.nil? ? @extensions.first : extensions(ext)
      end

    end

  end

end
