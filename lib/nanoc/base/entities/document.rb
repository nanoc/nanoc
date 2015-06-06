module Nanoc
  module Int
    # @api private
    class Document
      # @return [String]
      attr_reader :raw_content

      # @return [Hash]
      attr_reader :attributes

      # @return [Nanoc::Identifier]
      attr_accessor :identifier

      # @param [String] raw_content
      #
      # @param [Hash] attributes
      #
      # @param [String, Nanoc::Identifier] identifier
      #
      # @param [Hash] params Extra parameters. Unused.
      def initialize(raw_content, attributes, identifier, _params = {})
        @raw_content  = raw_content
        @attributes   = attributes.__nanoc_symbolize_keys_recursively
        @identifier   = Nanoc::Identifier.from(identifier)
      end

      # @return [void]
      def freeze
        attributes.__nanoc_freeze_recursively
        identifier.freeze
        raw_content.freeze
      end

      # @abstract
      #
      # @return Unique reference to this object
      def reference
        raise NotImplementedError
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
end
