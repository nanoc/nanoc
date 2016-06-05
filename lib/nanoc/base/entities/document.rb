module Nanoc
  module Int
    # @api private
    class Document
      include Contracts::Core

      C = Contracts

      # @return [Nanoc::Int::Content]
      attr_reader :content

      # @return [Hash]
      def attributes
        @attributes.value
      end

      # @return [Nanoc::Identifier]
      attr_accessor :identifier

      # @return [String, nil]
      attr_accessor :checksum_data

      CContent = C::Or[String, Nanoc::Int::Content]
      CAttributes = C::Or[Hash, Proc]
      CIdentifier = C::Or[String, Nanoc::Identifier]
      CChecksumData = C::Optional[C::Maybe[String]]

      Contract CContent, CAttributes, CIdentifier, C::KeywordArgs[checksum_data: CChecksumData] => C::Any
      # @param [String, Nanoc::Int::Content] content
      #
      # @param [Hash, Proc] attributes
      #
      # @param [String, Nanoc::Identifier] identifier
      #
      # @param [String, nil] checksum_data Used to determine whether the document has changed
      def initialize(content, attributes, identifier, checksum_data: nil)
        @content = Nanoc::Int::Content.create(content)
        @attributes = Nanoc::Int::LazyValue.new(attributes).map(&:__nanoc_symbolize_keys_recursively)
        @identifier = Nanoc::Identifier.from(identifier)
        @checksum_data = checksum_data
      end

      Contract C::None => self
      # @return [void]
      def freeze
        super
        @content.freeze
        @attributes.freeze
        self
      end

      Contract C::None => String
      # @abstract
      #
      # @return Unique reference to this object
      def reference
        raise NotImplementedError
      end

      Contract C::None => String
      def inspect
        "<#{self.class} identifier=\"#{identifier}\">"
      end

      Contract C::None => C::Num
      def hash
        self.class.hash ^ identifier.hash
      end

      Contract C::Any => C::Bool
      def ==(other)
        other.respond_to?(:identifier) && identifier == other.identifier
      end
      alias eql? ==
    end
  end
end
