# frozen_string_literal: true

module Nanoc
  class PostCompileItemRepCollectionView < Nanoc::BasicItemRepCollectionView
    # @api private
    def view_class
      Nanoc::PostCompileItemRepView
    end
  end
end
