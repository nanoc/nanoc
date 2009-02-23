module Nanoc

  # A Nanoc::Layout represents a layout in a nanoc site. It has content,
  # attributes (for determining which filter to use for laying out a page), an
  # identifier (because layouts are organised hierarchically), and a
  # modification time (to speed up compilation).
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

    # This layout's identifier, starting and ending with a slash.
    attr_reader :identifier

    # The time when this layout was last modified.
    attr_reader :mtime

    # Creates a new layout.
    #
    # +content+:: The raw content of this layout.
    #
    # +attributes+:: A hash containing this layout's attributes.
    #
    # +identifier+:: This layout's identifier.
    #
    # +mtime+:: The time when this layout was last modified.
    def initialize(content, attributes, identifier, mtime=nil)
      @content    = content
      @attributes = attributes.clean
      @identifier = identifier.cleaned_identifier
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
