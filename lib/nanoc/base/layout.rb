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

    attr_reader   :content, :attributes, :path, :mtime
    attr_accessor :site

    # Creates a new layout.
    def initialize(content, attributes, path, mtime=nil)
      @content    = content
      @attributes = attributes.clean
      @path       = path.cleaned_path
      @mtime      = mtime
    end

    # Returns a proxy (LayoutProxy) for this layout.
    def to_proxy
      @proxy ||= LayoutProxy.new(self)
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
