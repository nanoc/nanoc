module Nanoc

  # Nanoc::LayoutProcessor is responsible for layouting pages. It is the
  # (abstract) superclass for all layout processors. Subclasses should
  # override the +run+ method.
  class LayoutProcessor < Plugin

    # Creates a new layout processor for the given page and site.
    # +other_assigns+ is a hash for which the pairs will be available
    # as instance variables when compiling.
    def initialize(page, site, other_assigns={})
      @page          = page
      @pages         = site.pages.map { |p| p.to_proxy }
      @config        = site.config
      @site          = site
      @other_assigns = other_assigns
    end

    # Runs the layout processor. Subclasses should override this method. This
    # method returns the layouted content.
    def run(layout)
      error 'LayoutProcessor#run must be overridden'
    end

    class << self

      attr_accessor :extensions # :nodoc:

      # Sets or returns the extensions for this layout processor.
      # 
      # When given a list of extension symbols, sets the extensions for
      # this layout processor. When given nothing, returns an array of
      # extension symbols.
      def extensions(*exts)
        @extensions = [] unless instance_variable_defined?(:@extensions)
        exts.empty? ? @extensions : @extensions = exts
      end

      # Sets or returns the extension for this layout processor.
      # 
      # When given an extension symbols, sets the extension for this layout
      # processor. When given nothing, returns the extension.
      def extension(ext=nil)
        @extensions = [] unless instance_variable_defined?(:@extensions)
        ext.nil? ? @extensions.first : extensions(ext)
      end

    end

  end

end
