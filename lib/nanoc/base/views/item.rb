# encoding: utf-8

module Nanoc
  class ItemView
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

    def hash
      self.class.hash ^ identifier.hash
    end

    def identifier
      @item.identifier
    end

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

    def binary?
      @item.binary?
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
