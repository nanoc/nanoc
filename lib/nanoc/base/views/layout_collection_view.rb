# frozen_string_literal: true

module Nanoc
  class LayoutCollectionView < ::Nanoc::IdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::LayoutView
    end
  end
end
