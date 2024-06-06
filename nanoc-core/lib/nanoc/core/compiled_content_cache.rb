# frozen_string_literal: true

module Nanoc
  module Core
    # Represents a cache than can be used to store already compiled content,
    # to prevent it from being needlessly recompiled.
    #
    # @api private
    class CompiledContentCache < ::Nanoc::Core::Store
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
      def initialize(config:)
        @textual_cache = Nanoc::Core::TextualCompiledContentCache.new(config:)
        @binary_cache = Nanoc::Core::BinaryCompiledContentCache.new(config:)

        @wrapped_caches = [@textual_cache, @binary_cache]
      end

      contract Nanoc::Core::ItemRep => C::Maybe[C::HashOf[Symbol => Nanoc::Core::Content]]
      # Returns the cached compiled content for the given item representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names. and the values the compiled content at the given snapshot.
      def [](rep)
        textual_content_map = @textual_cache[rep]
        binary_content_map = @binary_cache[rep]

        # If either the textual or the binary content cache is nil, assume the
        # cache is entirely absent.
        #
        # This is necessary to support the case where only textual content is
        # cached (which was the case in older versions of Nanoc).
        return nil if [textual_content_map, binary_content_map].any?(&:nil?)

        textual_content_map.merge(binary_content_map)
      end

      contract Nanoc::Core::ItemRep, C::HashOf[Symbol => Nanoc::Core::Content] => C::Any
      # Sets the compiled content for the given representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names and the values the compiled content at the given snapshot.
      def []=(rep, content)
        @textual_cache[rep] = content.select { |_key, c| c.textual? }
        @binary_cache[rep] = content.select { |_key, c| c.binary? }
      end

      def prune(items:)
        @wrapped_caches.each { |w| w.prune(items:) }
      end

      # True if there is cached compiled content available for this item, and
      # all entries are present (either textual or binary).
      def full_cache_available?(rep)
        @textual_cache.include?(rep) && @binary_cache.include?(rep)
      end

      def load(*args)
        @wrapped_caches.each { |w| w.load(*args) }
      end

      def store(*args)
        @wrapped_caches.each { |w| w.store(*args) }
      end
    end
  end
end
