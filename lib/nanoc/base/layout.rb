module Nanoc

  # A Layout represents a layout in a nanoc site. It has content, attributes
  # (for determining which filter to use for laying out a page), a path
  # (because layouts are organised hierarchically), and a modification time
  # (to speed up compilation).
  class Layout

    # Default values for layouts.
    PAGE_DEFAULTS = {
      :filter => 'erb'
    }

    attr_reader   :content, :attributes, :path
    attr_accessor :site

    # Creates a new layout.
    def initialize(content, attributes, path, mtime=nil)
      @content    = content
      @attributes = attributes
      @path       = path.cleaned_path
      @mtime      = mtime
    end

    # Returns a proxy (LayoutProxy) for this layout.
    def to_proxy
      @proxy ||= LayoutProxy.new(self)
    end

    # Returns true if there exists a compiled page that is older than the
    # layout, false otherwise. Also returns true if the layout modification
    # time isn't known.
    def outdated?
      # Outdated if we don't know
      return true if @mtime.nil?

      # Get pages for this layout
      pages = @site.pages.select { |p| p.layout == self }

      # Get mtimes for pages for this layout
      compiled_page_mtimes = pages.map do |page|
        path = page.path_on_filesystem
        File.file?(path) ? File.stat(path).mtime : nil
      end.compact

      # Check if there are any newer pages
      compiled_page_mtimes.any? { |compiled_page_mtime| @mtime > compiled_page_mtime }
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return PAGE_DEFAULTS[name]
    end

    # Returns the filter class needed for this layout.
    def filter_class
      if attribute_named(:extension).nil?
        PluginManager.instance.filter(attribute_named(:filter).to_sym)
      else
        PluginManager.instance.layout_processor(attribute_named(:extension))
      end
    end

  end

end
