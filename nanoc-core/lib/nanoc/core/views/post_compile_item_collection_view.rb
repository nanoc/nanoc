# frozen_string_literal: true

module Nanoc
  module Core
    class PostCompileItemCollectionView < Nanoc::Core::IdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Core::PostCompileItemView
      end
    end
  end
end
