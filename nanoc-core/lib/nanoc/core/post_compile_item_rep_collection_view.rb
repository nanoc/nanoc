# frozen_string_literal: true

module Nanoc
  module Core
    class PostCompileItemRepCollectionView < Nanoc::Core::BasicItemRepCollectionView
      # @api private
      def view_class
        Nanoc::Core::PostCompileItemRepView
      end
    end
  end
end
