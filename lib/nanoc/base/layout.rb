module Nanoc

  # A Nanoc::Layout represents a layout in a nanoc site. It has content,
  # attributes (for determining which filter to use for laying out a page), a
  # path (because layouts are organised hierarchically), and a modification
  # time (to speed up compilation).
  class Layout

    # Default values for layouts.
    DEFAULTS = {
      :filter => 'erb'
    }

    # The Nanoc::Site this layout belongs to.
    attr_accessor :site

    # The raw content of this layout.
    attr_reader :content

    # A hash containing this layout's attributes.
    attr_reader :attributes

    # This layout's path, starting and ending with a slash.
    attr_reader :path

    # The time when this layout was last modified.
    attr_reader :mtime

    # Creates a new layout.
    #
    # +content+:: The raw content of this layout.
    #
    # +attributes+:: A hash containing this layout's attributes.
    #
    # +path+:: This layout's path, starting and ending with a slash.
    #
    # +mtime+:: The time when this layout was last modified.
    def initialize(content, attributes, path, mtime=nil)
      @content    = content
      @attributes = attributes.clean
      @path       = path.cleaned_path
      @mtime      = mtime
    end

    # Returns a proxy (Nanoc::LayoutProxy) for this layout.
    def to_proxy
      @proxy ||= LayoutProxy.new(self)
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return DEFAULTS[name]
    end

    # Returns the filter class needed for this layout.
    def filter_class
      Nanoc::Filter.named(attribute_named(:filter))
    end

  end

end
