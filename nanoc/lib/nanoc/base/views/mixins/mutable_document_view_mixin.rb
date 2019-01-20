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
      _unwrap.content = Nanoc::Core::Content.create(arg)
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
        Nanoc::CompilationItemView,
        Nanoc::LayoutView,
      ])
      if disallowed_value_classes.include?(value.class)
        raise DisallowedAttributeValueError.new(value)
      end

      _unwrap.set_attribute(key, value)
    end

    # Sets the identifier to the given argument.
    #
    # @param [String, Nanoc::Core::Identifier] arg
    def identifier=(arg)
      _unwrap.identifier = Nanoc::Core::Identifier.from(arg)
    end

    # Updates the attributes based on the given hash.
    #
    # @param [Hash] hash
    #
    # @return [self]
    def update_attributes(hash)
      hash.each { |k, v| _unwrap.set_attribute(k, v) }
      self
    end
  end
end
