# frozen_string_literal: true

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
    # @param [Boolean] binary Whether or not this item is binary
    #
    # @param [String] filename Absolute path to the file
    #   containing this content (if any)
    #
    # @return [self]
    def create(content, attributes, identifier, binary: false, filename: nil)
      content = Nanoc::Int::Content.create(content, binary: binary, filename: filename)
      @objects = @objects.add(Nanoc::Int::Item.new(content, attributes, identifier))
      self
    end
  end
end
