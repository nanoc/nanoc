# frozen_string_literal: true

module Nanoc
  module Core
    class ItemCollectionWithoutRepsView < ::Nanoc::Core::IdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Core::BasicItemView
      end
    end
  end
end
