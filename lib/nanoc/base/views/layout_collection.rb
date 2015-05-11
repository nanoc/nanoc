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
      @layouts
    end

    # @api private
    def view_class
      Nanoc::LayoutView
    end

    # Calls the given block once for each layout, passing that layout as a parameter.
    #
    # @yieldparam [Nanoc::LayoutView] layout
    #
    # @yieldreturn [void]
    def each
      @layouts.each { |l| yield view_class.new(l) }
      self
    end
  end
end
