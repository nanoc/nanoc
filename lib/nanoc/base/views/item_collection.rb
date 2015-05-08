# encoding: utf-8

module Nanoc
  class ItemCollectionView
    include Enumerable

    # @api private
    def initialize(items)
      @items = items
    end

    # @api private
    def unwrap
      @items
    end

    def each
      @items.each { |i| yield Nanoc::ItemView.new(i) }
    end

    def at(arg)
      item = @items.at(arg)
      item && Nanoc::ItemView.new(item)
    end

    def [](*args)
      res = @items[*args]
      case res
      when Array
        res.map { |r| Nanoc::ItemView.new(r) }
      when nil
        nil
      else
        Nanoc::ItemView.new(res)
      end
    end
  end
end
