# frozen_string_literal: true

module Nanoc
  module Core
    module MutableDocumentViewMixin
      # @api private
      class DisallowedAttributeValueError < Nanoc::Core::Error
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
        if disallowed_value_class?(value.class)
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

      private

      def disallowed_value_class?(klass)
        # NOTE: We’re explicitly disabling Style/MultipleComparison, because
        # the suggested alternative (Array#include?) carries a measurable
        # performance penatly.
        #
        # rubocop:disable Style/MultipleComparison
        klass == Nanoc::Core::Item ||
          klass == Nanoc::Core::Layout ||
          klass == Nanoc::Core::CompilationItemView ||
          klass == Nanoc::Core::LayoutView
        # rubocop:enable Style/MultipleComparison
      end
    end
  end
end
