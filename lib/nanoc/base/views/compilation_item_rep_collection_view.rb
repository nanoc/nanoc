# frozen_string_literal: true

module Nanoc
  class CompilationItemRepCollectionView < ::Nanoc::BasicItemRepCollectionView
    # @api private
    def view_class
      Nanoc::CompilationItemRepView
    end
  end
end
