# encoding: utf-8

module Nanoc3

  # Represents a layout in a nanoc site. It has content, attributes, an
  # identifier and a modification time (to speed up compilation).
  class Layout

    # @return [Nanoc3::Site] The site this layout belongs to
    attr_accessor :site

    # @return [String] The raw content of this layout
    attr_reader :raw_content

    # @return [Hash] This layout's attributes
    attr_reader :attributes

    # @return [String] This layout's identifier, starting and ending with a
    # slash
    attr_accessor :identifier

    # @return [Time] The time where this layout was last modified
    attr_reader   :mtime

    # @return [String] The checksum of this layout that was in effect during
    #   the previous site compilation
    attr_accessor :old_checksum

    # @return [String] The current, up-to-date checksum of this layout
    attr_reader   :new_checksum

    # Creates a new layout.
    #
    # @param [String] raw_content The raw content of this layout.
    #
    # @param [Hash] attributes A hash containing this layout's attributes.
    #
    # @param [String] identifier This layout's identifier.
    #
    # @param [Time, Hash] params Extra parameters. For backwards
    #   compatibility, this can be a Time instance indicating the time when
    #   this layout was last modified (mtime).
    #
    # @option params [Time, nil] :mtime (nil) The time when this layout was
    #   last modified
    #
    # @option params [String, nil] :checksum (nil) The current, up-to-date
    #   checksum of this layout
    def initialize(raw_content, attributes, identifier, params=nil)
      # Get mtime and checksum
      params ||= {}
      params = { :mtime => params } if params.is_a?(Time)
      @new_checksum = params[:checksum]
      @mtime        = params[:mtime]

      @raw_content  = raw_content
      @attributes   = attributes.symbolize_keys
      @identifier   = identifier.cleaned_identifier
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
