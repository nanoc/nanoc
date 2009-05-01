module Nanoc3

  # A Nanoc3::Layout represents a layout in a nanoc site. It has content,
  # attributes (for determining which filter to use for laying out an item),
  # an identifier (because layouts are organised hierarchically), and a
  # modification time (to speed up compilation).
  class Layout

    # The Nanoc3::Site this layout belongs to.
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

    # Returns a proxy (Nanoc3::LayoutProxy) for this layout.
    def to_proxy
      @proxy ||= LayoutProxy.new(self)
    end

    # Returns the attribute with the given name.
    def [](name)
      @attributes[name]
    end

  end

end
