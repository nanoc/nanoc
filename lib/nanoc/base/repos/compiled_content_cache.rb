# frozen_string_literal: true

module Nanoc::Int
  # Represents a cache than can be used to store already compiled content,
  # to prevent it from being needlessly recompiled.
  #
  # @api private
  class CompiledContentCache < ::Nanoc::Int::Store
    include Nanoc::Int::ContractsSupport

    contract C::KeywordArgs[site: C::Maybe[Nanoc::Int::Site], items: C::IterOf[Nanoc::Int::Item]] => C::Any
    def initialize(site: nil, items:)
      super(Nanoc::Int::Store.tmp_path_for(site: site, store_name: 'compiled_content'), 2)

      @items = items
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

    contract Nanoc::Int::ItemRep, C::HashOf[Symbol => Nanoc::Int::Content] => self
    # Sets the compiled content for the given representation.
    #
    # This cached compiled content is a hash where the keys are the snapshot
    # names. and the values the compiled content at the given snapshot.
    def []=(rep, content)
      @cache[rep.item.identifier] ||= {}
      @cache[rep.item.identifier][rep.name] = content
      self
    end

    protected

    def data
      @cache
    end

    def data=(new_data)
      @cache = {}

      item_identifiers = Set.new(@items.map(&:identifier))

      new_data.each_pair do |item_identifier, content_per_rep|
        if item_identifiers.include?(item_identifier)
          @cache[item_identifier] ||= content_per_rep
        end
      end
    end
  end
end
