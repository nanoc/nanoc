# encoding: utf-8

module Nanoc
  class MutableLayoutCollectionView < Nanoc::LayoutCollectionView
    # @api private
    def view_class
      Nanoc::MutableLayoutView
    end

    def create(content, attributes, identifier, params = {})
      @layouts << Nanoc::Int::Layout.new(content, attributes, identifier, params)
    end

    def delete_if(&block)
      @layouts.delete_if(&block)
    end
  end
end
