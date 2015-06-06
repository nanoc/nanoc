module Nanoc::Int
  # Represents a layout in a nanoc site. It has content, attributes, an
  # identifier and a modification time (to speed up compilation).
  #
  # @api private
  class Layout
    # @return [String] The raw content of this layout
    attr_reader :raw_content

    # @return [Hash] This layout's attributes
    attr_reader :attributes

    # @return [Nanoc::Identifier] This layout's identifier
    attr_accessor :identifier

    # Creates a new layout.
    #
    # @param [String] raw_content The raw content of this layout.
    #
    # @param [Hash] attributes A hash containing this layout's attributes.
    #
    # @param [String] identifier This layout's identifier.
    #
    # @param [Hash] params Extra parameters. Unused.
    def initialize(raw_content, attributes, identifier, _params = {})
      @raw_content  = raw_content
      @attributes   = attributes.__nanoc_symbolize_keys_recursively
      @identifier   = Nanoc::Identifier.from(identifier)
    end

    # Requests the attribute with the given key.
    #
    # @param [Symbol] key The name of the attribute to fetch.
    #
    # @return [Object] The value of the requested attribute.
    def [](key)
      @attributes[key]
    end

    def []=(key, value)
      @attributes[key] = value
    end

    # Returns the type of this object. Will always return `:layout`, because
    # this is a layout. For items, this method returns `:item`.
    #
    # @api private
    #
    # @return [Symbol] :layout
    def type
      :layout
    end

    # Prevents all further modifications to the layout.
    #
    # @return [void]
    def freeze
      attributes.__nanoc_freeze_recursively
      identifier.freeze
      raw_content.freeze
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [type, identifier]
    end

    def inspect
      "<#{self.class} identifier=\"#{identifier}\">"
    end

    def hash
      self.class.hash ^ identifier.hash
    end

    def eql?(other)
      self.class == other.class && identifier == other.identifier
    end

    def ==(other)
      self.eql?(other)
    end
  end
end
