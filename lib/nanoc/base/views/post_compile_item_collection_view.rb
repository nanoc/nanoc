module Nanoc
  class PostCompileItemCollectionView < Nanoc::IdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::PostCompileItemView
    end
  end
end
