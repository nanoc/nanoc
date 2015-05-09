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

    # @api private
    def view_class
      Nanoc::ItemView
    end

    def each
      @items.each { |i| yield view_class.new(i) }
    end

    def at(arg)
      item = @items.at(arg)
      item && view_class.new(item)
    end

    def [](*args)
      res = @items[*args]
      case res
      when Array
        res.map { |r| view_class.new(r) }
      when nil
        nil
      else
        view_class.new(res)
      end
    end
  end
end
