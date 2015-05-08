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
      @item
    end

    def each
      @items.each { |i| yield Nanoc::ItemView.new(i) }
    end

    def at(arg)
      Nanoc::ItemView.new(@items.at(arg))
    end

    def [](*args)
      res = @items[*args]
      case res
      when Array
        res.map { Nanoc::ItemView.new(res) }
      else
        Nanoc::ItemView.new(res)
      end
    end
  end
end
