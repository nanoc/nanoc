# frozen_string_literal: true

module Nanoc
  class ItemCollectionWithRepsView < ::Nanoc::IdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::ItemWithRepsView
    end
  end
end
