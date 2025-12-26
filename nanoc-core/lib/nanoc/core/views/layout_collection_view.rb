# frozen_string_literal: true

module Nanoc
  module Core
    class LayoutCollectionView < ::Nanoc::Core::IdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Core::LayoutView
      end
    end
  end
end
