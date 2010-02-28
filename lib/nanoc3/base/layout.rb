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

    # @return [Time] The time when this layout was last modified
    attr_reader :mtime

    # Creates a new layout.
    #
    # @param [String] raw_content The raw content of this layout.
    #
    # @param [Hash] attributes A hash containing this layout's attributes.
    #
    # @param [String] identifier This layout's identifier.
    #
    # @param [Time, Hash, nil] params_or_mtime Extra parameters for the
    # layout, or the time when this layout was last modified (deprecated).
    #
    # @option params_or_mtime [Time, nil] :mtime (nil) The time when this
    # layout was last modified
    def initialize(raw_content, attributes, identifier, params_or_mtime=nil)
      # Get params and mtime
      # TODO [in nanoc 4.0] clean this up
      if params_or_mtime.nil? || params_or_mtime.is_a?(Time)
        params = {}
        @mtime = params_or_mtime
      elsif params_or_mtime.is_a?(Hash)
        params = params_or_mtime
        @mtime = params[:mtime]
      end

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
