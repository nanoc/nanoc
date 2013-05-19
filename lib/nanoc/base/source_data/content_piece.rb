# encoding: utf-8

module Nanoc

  # Has content, attributes and an identifier.
  class ContentPiece

    # @return [String]
    attr_accessor :identifier

    # @return [String] This content piece's raw content (only available for
    #   textual content pieces)
    attr_reader :content

    # @return [String] The filename pointing to the file containing this content
    #   piece’s content
    attr_accessor :filename

    # @return [Hash]
    attr_accessor :attributes

    # @return [Nanoc::Site] The site this content piece belongs to
    attr_accessor :site

    # Creates a new content piece with the given content or filename, attributes
    # and identifier.
    #
    # @param [String] content_or_filename The uncompiled content (if it is a
    # textual content piece) or the path to the filename containing the content
    # (if it is a binary content piece).
    #
    # @param [Hash] attributes
    #
    # @param [String] identifier This content piece's identifier.
    #
    # @option params [Symbol, nil] :binary (true) Whether or not this content
    # piece is binary
    def initialize(content_or_filename, attributes, identifier, params={})
      if identifier.is_a?(String)
        identifier = Nanoc::Identifier.from_string(identifier)
      end

      if content_or_filename.nil?
        raise "attempted to create a #{self.class} with no content/filename (identifier #{identifier})"
      end

      # Get type and raw content or raw filename
      @is_binary = params.fetch(:binary, false)
      if @is_binary
        @filename = content_or_filename
      else
        @filename = attributes[:content_filename]
        @content  = content_or_filename
      end

      # Get rest of params
      @attributes   = attributes.symbolize_keys_recursively
      @identifier   = identifier
    end

    # Requests the attribute with the given key.
    #
    # @param [Symbol] key The name of the attribute to fetch
    #
    # @return [Object] The value of the requested attribute
    def [](key)
      Nanoc::NotificationCenter.post(:visit_started, self)
      Nanoc::NotificationCenter.post(:visit_ended,   self)

      @attributes[key]
    end

    # Sets the attribute with the given key to the given value.
    #
    # @param [Symbol] key The name of the attribute to set
    #
    # @param [Object] value The value of the attribute to set
    def []=(key, value)
      @attributes[key] = value
    end

    # @return [Boolean] True if the content piece is binary; false if it is not
    def binary?
      !!@is_binary
    end

    # @return [Symbol] the type of this object as a symbol (`:item`, `:layout`, ...)
    #
    # @api private
    #
    # @abstract
    def type
      raise NotImplementedError
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [ type, self.identifier ]
    end

    # @see Object#freeze
    def freeze
      attributes.freeze_recursively
      identifier.freeze
      filename.freeze if filename
      content.freeze  if content
    end

    # @see Object#inspect
    def inspect
      "<#{self.class} identifier=#{self.identifier.inspect} binary?=#{self.binary?}>"
    end

    # @see Object#hash
    def hash
      self.class.hash ^ self.identifier.hash
    end

    # @see Object#eql?
    def eql?(other)
      self.class == other.class && self.identifier == other.identifier
    end

    # @see Object#==
    def ==(other)
      self.eql?(other)
    end

  end

end
