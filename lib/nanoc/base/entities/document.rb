module Nanoc
  module Int
    # @api private
    class Document
      # @return [Nanoc::Int::Content]
      attr_reader :content

      # @return [Hash]
      attr_reader :attributes

      # @return [Nanoc::Identifier]
      attr_accessor :identifier

      # @return [String, nil]
      attr_accessor :checksum_data

      # @param [String, Nanoc::Int::Content] content
      #
      # @param [Hash] attributes
      #
      # @param [String, Nanoc::Identifier] identifier
      #
      # @param [String, nil] checksum_data Used to determine whether the document has changed
      def initialize(content, attributes, identifier, checksum_data: nil)
        @content = Nanoc::Int::Content.create(content)
        @attributes = attributes.__nanoc_symbolize_keys_recursively
        @identifier = Nanoc::Identifier.from(identifier)
        @checksum_data = checksum_data
      end

      # @return [void]
      def freeze
        super
        attributes.__nanoc_freeze_recursively
        content.freeze
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

      def ==(other)
        other.respond_to?(:identifier) && identifier == other.identifier
      end
      alias_method :eql?, :==
    end
  end
end
