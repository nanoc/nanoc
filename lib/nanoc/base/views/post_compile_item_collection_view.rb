# frozen_string_literal: true

module Nanoc
  class PostCompileItemCollectionView < Nanoc::IdentifiableCollectionView
    # @api private
    def view_class
      Nanoc::PostCompileItemView
    end
  end
end
