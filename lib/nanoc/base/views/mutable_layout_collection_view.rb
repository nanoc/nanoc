# frozen_string_literal: true

module Nanoc
  class MutableLayoutCollectionView < Nanoc::MutableIdentifiableCollectionView
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
      @objects = @objects.add(Nanoc::Int::Layout.new(content, attributes, identifier))
      self
    end
  end
end
