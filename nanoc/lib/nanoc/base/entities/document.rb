# frozen_string_literal: true

module Nanoc
  module Int
    # @api private
    class Document
      include Nanoc::Core::ContractsSupport

      # @return [Nanoc::Core::Content]
      attr_reader :content

      # @return [Hash]
      def attributes
        @attributes.value
      end

      # @return [Nanoc::Core::Identifier]
      attr_reader :identifier

      # @return [String, nil]
      attr_accessor :checksum_data

      # @return [String, nil]
      attr_accessor :content_checksum_data

      # @return [String, nil]
      attr_accessor :attributes_checksum_data

      c_content = C::Or[String, Nanoc::Core::Content]
      c_attributes = C::Or[Hash, Proc]
      c_identifier = C::Or[String, Nanoc::Core::Identifier]
      c_checksum_data = C::KeywordArgs[
        checksum_data: C::Optional[C::Maybe[String]],
        content_checksum_data: C::Optional[C::Maybe[String]],
        attributes_checksum_data: C::Optional[C::Maybe[String]],
      ]

      contract c_content, c_attributes, c_identifier, c_checksum_data => C::Any
      # @param [String, Nanoc::Core::Content] content
      #
      # @param [Hash, Proc] attributes
      #
      # @param [String, Nanoc::Core::Identifier] identifier
      #
      # @param [String, nil] checksum_data
      #
      # @param [String, nil] content_checksum_data
      #
      # @param [String, nil] attributes_checksum_data
      def initialize(content, attributes, identifier, checksum_data: nil, content_checksum_data: nil, attributes_checksum_data: nil)
        @content = Nanoc::Core::Content.create(content)
        @attributes = Nanoc::Core::LazyValue.new(attributes).map(&:__nanoc_symbolize_keys_recursively)
        @identifier = Nanoc::Core::Identifier.from(identifier)

        @checksum_data = checksum_data
        @content_checksum_data = content_checksum_data
        @attributes_checksum_data = attributes_checksum_data
      end

      contract C::None => self
      # @return [void]
      def freeze
        super
        @content.freeze
        @attributes.freeze
        self
      end

      contract String => self
      def with_identifier_prefix(prefix)
        other = dup
        other.identifier = @identifier.prefix(prefix)
        other
      end

      contract C::None => String
      # @abstract
      #
      # @return Unique reference to this object
      def reference
        raise NotImplementedError
      end

      contract C::Or[Nanoc::Core::Identifier, String] => Nanoc::Core::Identifier
      def identifier=(new_identifier)
        @identifier = Nanoc::Core::Identifier.from(new_identifier)
      end

      contract Nanoc::Core::Content => C::Any
      def content=(new_content)
        @content = new_content

        @checksum_data = nil
        @content_checksum_data = nil
      end

      def set_attribute(key, value)
        attributes[key] = value

        @checksum_data = nil
        @attributes_checksum_data = nil
      end

      contract C::None => String
      def inspect
        "<#{self.class} identifier=\"#{identifier}\">"
      end

      contract C::None => C::Num
      def hash
        self.class.hash ^ identifier.hash
      end

      contract C::Any => C::Bool
      def ==(other)
        other.respond_to?(:identifier) && identifier == other.identifier
      end

      contract C::Any => C::Bool
      def eql?(other)
        other.is_a?(self.class) && identifier == other.identifier
      end
    end
  end
end
