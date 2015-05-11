# encoding: utf-8

module Nanoc
  class MutableLayoutCollectionView < Nanoc::LayoutCollectionView
    # @api private
    def view_class
      Nanoc::MutableLayoutView
    end

    # Creates a new layout and adds it to the site’s collection of layouts.
    #
    # @param [String] content The layout content.
    #
    # @param [Hash] attributes A hash containing this layout's attributes.
    #
    # @param [Nanoc::Identifier, String] identifier This layout's identifier.
    #
    # @return [self]
    def create(content, attributes, identifier)
      @layouts << Nanoc::Int::Layout.new(content, attributes, identifier)
      self
    end

    # Deletes every layout for which the block evaluates to true.
    #
    # @yieldparam [Nanoc::LayoutView] layout
    #
    # @yieldreturn [Boolean]
    #
    # @return [self]
    def delete_if(&block)
      @layouts.delete_if(&block)
      self
    end
  end
end
