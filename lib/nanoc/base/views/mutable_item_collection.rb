# encoding: utf-8

module Nanoc
  class MutableItemCollectionView < Nanoc::ItemCollectionView
    # @api private
    def view_class
      Nanoc::MutableItemView
    end

    def create(content, attributes, identifier, params = {})
      @items << Nanoc::Int::Item.new(content, attributes, identifier, params)
    end

    def delete_if(&block)
      @items.delete_if(&block)
    end

    def concat(other)
      @items.concat(other)
    end
  end
end
