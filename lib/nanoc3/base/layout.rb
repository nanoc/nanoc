# encoding: utf-8

module Nanoc3

  # A Nanoc3::Layout represents a layout in a nanoc site. It has content,
  # attributes (for determining which filter to use for laying out an item),
  # an identifier (because layouts are organised hierarchically), and a
  # modification time (to speed up compilation).
  class Layout

    # The Nanoc3::Site this layout belongs to.
    attr_accessor :site

    # The raw content of this layout.
    attr_reader :raw_content

    # A hash containing this layout's attributes.
    attr_reader :attributes

    # This layout's identifier, starting and ending with a slash.
    attr_accessor :identifier

    # The time when this layout was last modified.
    attr_reader :mtime

    # Creates a new layout.
    #
    # @param [String] content The raw content of this layout.
    #
    # @param [Hash] attributes A hash containing this layout's attributes.
    #
    # @param [String] identifier This layout's identifier.
    #
    # @param [Time, nil] mtime The time when this layout was last modified.
    def initialize(raw_content, attributes, identifier, mtime=nil)
      @raw_content  = raw_content
      @attributes   = attributes.symbolize_keys
      @identifier   = identifier.cleaned_identifier
      @mtime        = mtime
    end

    # Requests the attribute with the given key.
    #
    # @param [Symbol] key The name of the attribute to fetch.
    #
    # @return [Object] The value of the requested attribute.
    def [](key)
      @attributes[key]
    end

    def inspect
      "<#{self.class}:0x#{self.object_id.to_s(16)} identifier=#{self.identifier}>"
    end

  end

end
