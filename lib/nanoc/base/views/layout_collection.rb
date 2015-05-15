# encoding: utf-8

module Nanoc
  class LayoutCollectionView < ::Nanoc::IdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::LayoutView
    end
  end
end
