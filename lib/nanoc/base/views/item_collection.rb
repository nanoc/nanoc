# encoding: utf-8

module Nanoc
  class ItemCollectionView < ::Nanoc::IdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::ItemView
    end
  end
end
