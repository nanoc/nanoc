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
    # @option params [Boolean] :binary (false) Whether or not this item is
    #   binary
    #
    # @option params [String] :filename (nil) Absolute path to the file
    #   containing this content (if any)
    #
    # @return [self]
    def create(content, attributes, identifier, params = {})
      content = Nanoc::Int::Content.create(content, params)
      @objects << Nanoc::Int::Item.new(content, attributes, identifier)
      self
    end
  end
end
