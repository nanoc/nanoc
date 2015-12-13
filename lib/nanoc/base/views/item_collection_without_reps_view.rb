module Nanoc
  class ItemCollectionWithoutRepsView < ::Nanoc::IdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::ItemWithoutRepsView
    end
  end
end
