# frozen_string_literal: true

module Nanoc
  module Core
    # Represents a cache than can be used to store already compiled content,
    # to prevent it from being needlessly recompiled.
    #
    # @api private
    class TextualCompiledContentCache < ::Nanoc::Core::Store
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
      def initialize(config:)
        super(Nanoc::Core::Store.tmp_path_for(config:, store_name: 'compiled_content'), 4)

        @cache = {}
      end

      contract Nanoc::Core::ItemRep => C::Maybe[C::HashOf[Symbol => Nanoc::Core::Content]]
      # Returns the cached compiled content for the given item representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names, and the values the compiled content at the given snapshot.
      def [](rep)
        item_cache = @cache[rep.item.identifier] || {}
        item_cache[rep.name]
      end

      contract Nanoc::Core::ItemRep => C::Bool
      def include?(rep)
        item_cache = @cache[rep.item.identifier] || {}
        item_cache.key?(rep.name)
      end

      contract Nanoc::Core::ItemRep, C::HashOf[Symbol => Nanoc::Core::Content] => C::Any
      # Sets the compiled content for the given representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names, and the values the compiled content at the given snapshot.
      def []=(rep, content)
        # FIXME: once the binary content cache is properly enabled (no longer
        # behind a feature flag), change contract to be TextualContent, rather
        # than Content.

        @cache[rep.item.identifier] ||= {}
        @cache[rep.item.identifier][rep.name] = content
      end

      def prune(items:)
        item_identifiers = Set.new(items.map(&:identifier))

        @cache.each_key do |key|
          # TODO: remove unused item reps
          next if item_identifiers.include?(key)

          @cache.delete(key)
        end
      end

      # True if there is cached compiled content available for this item, and
      # all entries are textual.
      def full_cache_available?(rep)
        cache = self[rep]
        cache ? cache.none? { |_snapshot_name, content| content.binary? } : false
      end

      protected

      def data
        @cache
      end

      def data=(new_data)
        @cache = {}

        new_data.each_pair do |item_identifier, content_per_rep|
          @cache[item_identifier] ||= content_per_rep
        end
      end
    end
  end
end
