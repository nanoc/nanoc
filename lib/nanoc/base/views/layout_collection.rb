# encoding: utf-8

module Nanoc
  class LayoutCollectionView
    include Enumerable

    # @api private
    def initialize(layouts)
      @layouts = layouts
    end

    # @api private
    def unwrap
      @item
    end

    def each
      @layouts.each { |l| yield Nanoc::LayoutView.new(l) }
    end
  end
end
