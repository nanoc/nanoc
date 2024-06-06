# frozen_string_literal: true

module Nanoc
  module Core
    module DocumentViewMixin
      # @api private
      def initialize(document, context)
        super(context)
        @document = document
      end

      # @api private
      def _unwrap
        @document
      end

      # @see Object#==
      def ==(other)
        other.respond_to?(:identifier) && identifier == other.identifier
      end

      # @see Object#eql?
      def eql?(other)
        other.is_a?(self.class) && identifier.eql?(other.identifier)
      end

      # @see Object#hash
      def hash
        [self.class, identifier].hash
      end

      # @return [Nanoc::Core::Identifier]
      def identifier
        _unwrap.identifier
      end

      # @see Hash#[]
      def [](key)
        @context.dependency_tracker.bounce(_unwrap, attributes: [key])
        _unwrap.attributes[key]
      end

      # @return [Hash]
      def attributes
        # TODO: Refine dependencies
        @context.dependency_tracker.bounce(_unwrap, attributes: true)
        _unwrap.attributes
      end

      # @see Hash#fetch
      def fetch(key, fallback = Nanoc::Core::UNDEFINED, &)
        @context.dependency_tracker.bounce(_unwrap, attributes: [key])

        if _unwrap.attributes.key?(key)
          _unwrap.attributes[key]
        elsif !Nanoc::Core::UNDEFINED.equal?(fallback)
          fallback
        elsif block_given?
          yield(key)
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end

      # @see Hash#key?
      def key?(key)
        @context.dependency_tracker.bounce(_unwrap, attributes: [key])
        _unwrap.attributes.key?(key)
      end

      # @api private
      def reference
        _unwrap.reference
      end

      # @api private
      def raw_content
        @context.dependency_tracker.bounce(_unwrap, raw_content: true)
        _unwrap.content.string
      end

      def inspect
        "<#{self.class} identifier=#{_unwrap.identifier}>"
      end
    end
  end
end
