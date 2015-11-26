module Nanoc
  class AttributedItemCollectionView < Nanoc::IdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::AttributedItemView
    end
  end
end
