# frozen_string_literal: true

module Nanoc
  module Int
    # Represents a cache than can be used to store already compiled content,
    # to prevent it from being needlessly recompiled.
    #
    # @api private
    class CompositeCache < ::Nanoc::Int::Store
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
      def initialize(config:)
        @textual = Nanoc::Int::CompiledContentCache.new(config: config)
        @binary = Nanoc::Int::BinaryContentCache.new(config: config)

        @wrapped = [@textual, @binary]
      end

      contract Nanoc::Core::ItemRep => C::Maybe[C::HashOf[Symbol => Nanoc::Core::Content]]
      # Returns the cached compiled content for the given item representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names. and the values the compiled content at the given snapshot.
      def [](rep)
        textual = (@textual[rep] || {}).reject { |_, content| content.binary? }
        binary = @binary[rep] || {}

        cache = textual.merge(binary)

        return cache if equals_snapshot_def(rep, cache)

        nil
      end

      contract Nanoc::Core::ItemRep, C::HashOf[Symbol => Nanoc::Core::Content] => C::HashOf[Symbol => Nanoc::Core::Content]
      # Sets the compiled content for the given representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names and the values the compiled content at the given snapshot.
      def []=(rep, content)
        @wrapped.each { |w| w[rep] = content }

        # Required to adhere to the contract.
        content = content
      end

      def prune(*args)
        @wrapped.each { |w| w.prune(*args) }
      end

      def load(*args)
        @wrapped.each { |w| w.load(*args) }
      end

      def store(*args)
        @wrapped.each { |w| w.store(*args) }
      end

      private

      def equals_snapshot_def(rep, cache)
        return false if cache.empty?

        # Keys must match.
        rep_keys = Set.new(rep.snapshot_defs.map(&:name))
        cache_keys = Set.new(cache.keys)

        return false unless rep_keys == cache_keys

        # Types must match.
        rep.snapshot_defs.all? do |snapshot|
          snapshot.binary? == cache[snapshot.name].binary?
        end
      end
    end
  end
end
