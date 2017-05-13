# frozen_string_literal: true

module Nanoc
  module MutableDocumentViewMixin
    # @api private
    class DisallowedAttributeValueError < Nanoc::Error
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def message
        "The #{value.class} cannot be stored inside an attribute. Store its identifier instead."
      end
    end

    def raw_content=(arg)
      unwrap.content = Nanoc::Int::Content.create(arg)
    end

    # Sets the value for the given attribute.
    #
    # @param [Symbol] key
    #
    # @see Hash#[]=
    def []=(key, value)
      disallowed_value_classes = Set.new([
        Nanoc::Int::Item,
        Nanoc::Int::Layout,
        Nanoc::ItemWithRepsView,
        Nanoc::LayoutView,
      ])
      if disallowed_value_classes.include?(value.class)
        raise DisallowedAttributeValueError.new(value)
      end

      unwrap.attributes[key] = value
    end

    # Sets the identifier to the given argument.
    #
    # @param [String, Nanoc::Identifier] arg
    def identifier=(arg)
      unwrap.identifier = Nanoc::Identifier.from(arg)
    end

    # Updates the attributes based on the given hash.
    #
    # @param [Hash] hash
    #
    # @return [self]
    def update_attributes(hash)
      hash.each { |k, v| unwrap.attributes[k] = v }
      self
    end
  end
end
