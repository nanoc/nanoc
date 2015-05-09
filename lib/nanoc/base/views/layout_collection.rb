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

    # @api private
    def view_class
      Nanoc::LayoutView
    end

    def each
      @layouts.each { |l| yield view_class.new(l) }
    end
  end
end
