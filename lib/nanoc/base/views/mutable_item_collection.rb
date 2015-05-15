# encoding: utf-8

module Nanoc
  class MutableItemCollectionView < Nanoc::MutableIdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::MutableItemView
    end

    # Creates a new item and adds it to the site’s collection of items.
    #
    # @param [String] content The uncompiled item content (if it is a textual
    #   item) or the path to the filename containing the content (if it is a
    #   binary item).
    #
    # @param [Hash] attributes A hash containing this item's attributes.
    #
    # @param [Nanoc::Identifier, String] identifier This item's identifier.
    #
    # @param [Hash] params Extra parameters.
    #
    # @option params [Symbol, nil] :binary (true) Whether or not this item is
    #   binary
    #
    # @return [self]
    def create(content, attributes, identifier, params = {})
      @objects << Nanoc::Int::Item.new(content, attributes, identifier, params)
      self
    end
  end
end
