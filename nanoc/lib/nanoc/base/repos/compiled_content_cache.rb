# frozen_string_literal: true

module Nanoc::Int
  # Represents a cache than can be used to store already compiled content,
  # to prevent it from being needlessly recompiled.
  #
  # @api private
  class CompiledContentCache < ::Nanoc::Int::Store
    include Nanoc::Int::ContractsSupport

    contract C::KeywordArgs[config: Nanoc::Int::Configuration] => C::Any
    def initialize(config:)
      super(Nanoc::Int::Store.tmp_path_for(config: config, store_name: 'compiled_content'), 2)

      @cache = {}
    end

    contract Nanoc::Int::ItemRep => C::Maybe[C::HashOf[Symbol => Nanoc::Int::Content]]
    # Returns the cached compiled content for the given item representation.
    #
    # This cached compiled content is a hash where the keys are the snapshot
    # names. and the values the compiled content at the given snapshot.
    def [](rep)
      item_cache = @cache[rep.item.identifier] || {}
      item_cache[rep.name]
    end

    contract Nanoc::Int::ItemRep, C::HashOf[Symbol => Nanoc::Int::Content] => C::HashOf[Symbol => Nanoc::Int::Content]
    # Sets the compiled content for the given representation.
    #
    # This cached compiled content is a hash where the keys are the snapshot
    # names. and the values the compiled content at the given snapshot.
    def []=(rep, content)
      @cache[rep.item.identifier] ||= {}
      @cache[rep.item.identifier][rep.name] = content
    end

    def prune(items:)
      item_identifiers = Set.new(items.map(&:identifier))

      @cache.keys.each do |key|
        @cache.delete(key) unless item_identifiers.include?(key)
      end
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
