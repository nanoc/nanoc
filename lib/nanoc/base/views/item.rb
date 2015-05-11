# encoding: utf-8

module Nanoc
  class ItemView
    # @api private
    NONE = Object.new

    # @api private
    def initialize(item)
      @item = item
    end

    # @api private
    def unwrap
      @item
    end

    def ==(other)
      identifier == other.identifier
    end
    alias_method :eql?, :==

    def hash
      self.class.hash ^ identifier.hash
    end

    def identifier
      @item.identifier
    end

    # @see Hash#fetch
    def fetch(key, fallback=NONE, &block)
      res = @item[key] # necessary for dependency tracking

      if @item.attributes.key?(key)
        res
      else
        if !fallback.equal?(NONE)
          fallback
        elsif block_given?
          yield(key)
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end
    end

    # @see Hash#key?
    def key?(key)
      _res = @item[key] # necessary for dependency tracking
      @item.attributes.key?(key)
    end

    # @see Hash#[]
    def [](key)
      @item[key]
    end

    def compiled_content(params = {})
      @item.compiled_content(params)
    end

    def path(params = {})
      @item.path(params)
    end

    def children
      @item.children.map { |i| Nanoc::ItemView.new(i) }
    end

    def parent
      Nanoc::ItemView.new(@item.parent)
    end

    def binary?
      @item.binary?
    end

    def raw_content
      @item.raw_content
    end

    # @api private
    def reference
      @item.reference
    end

    # @api private
    def reps
      @item.reps.map { |r| Nanoc::ItemRepView.new(r) }
    end

    # @api private
    def raw_filename
      @item.raw_filename
    end

    # @api private
    def forced_outdated?
      @item.forced_outdated?
    end

    # @api private
    def __nanoc_checksum
      @item.__nanoc_checksum
    end
  end
end
