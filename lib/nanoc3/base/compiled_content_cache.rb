# encoding: utf-8

module Nanoc3

  # Represents a cache than can be used to store already compiled content,
  # to prevent it from being needlessly recompiled.
  #
  # @private
  class CompiledContentCache

    # @return [String] The filename where the cache will be loaded from
    #   and stored to
    attr_reader :filename

    # Creates a new cache for the given filename.
    #
    # @param [String] filename The filename where the cache will be loaded
    #   from and stored to
    def initialize(filename)
      require 'pstore'

      @filename = filename
    end

    # Loads the cache from the filesystem into memory.
    #
    # @return [void]
    def load
      cache = nil
      return if !File.file?(filename)
      pstore.transaction { cache = pstore[:compiled_content] }
    end

    # Stores the content of the (probably modified) in-memory cache to the
    #   filesystem.
    #
    # @return [void]
    def store
      FileUtils.mkdir_p(File.dirname(filename))
      pstore.transaction { pstore[:compiled_content] = cache }
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
      item_cache = cache[rep.item.identifier] || {}
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
      cache[rep.item.identifier] ||= {}
      cache[rep.item.identifier][rep.name] = content
    end

  private

    def cache
      @cache ||= {}
    end

    def pstore
      require 'pstore'
      @store ||= PStore.new(@filename)
    end

  end

end
