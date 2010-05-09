# encoding: utf-8

module Nanoc3

  # Represents a cache than can be used to store already compiled content,
  # to prevent it from being needlessly recompiled.
  #
  # @api private
  class CompiledContentCache < ::Nanoc3::Store

    def initialize
      super('tmp/compiled_content', 1)

      @cache = {}
    end

    # Returns the cached compiled content for the given item
    # representation. This cached compiled content is a hash where the keys
    # are the snapshot names and the values the compiled content at the
    # given snapshot.
    #
    # @param [Nanoc3::ItemRep] rep The item rep to fetch the content for
    #
    # @return [Hash<Symbol,String>] A hash containing the cached compiled
    #   content for the given item representation
    def [](rep)
      item_cache = self.cache[rep.item.identifier] || {}
      item_cache[rep.name]
    end

    # Sets the compiled content for the given representation.
    #
    # @param [Nanoc3::ItemRep] rep The item representation for which to set
    #   the compiled content
    #
    # @param [Hash<Symbol,String>] content A hash containing the compiled
    #   content of the given representation
    #
    # @return [void]
    def []=(rep, content)
      self.cache[rep.item.identifier] ||= {}
      self.cache[rep.item.identifier][rep.name] = content
    end

  protected

    attr_accessor :cache

    def data
      self.cache
    end

    def data=(new_data)
      self.cache = new_data
    end

  end

end
