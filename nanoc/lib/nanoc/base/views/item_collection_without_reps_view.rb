# frozen_string_literal: true

module Nanoc
  module Base
    class ItemCollectionWithoutRepsView < ::Nanoc::Base::IdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Base::BasicItemView
      end
    end
  end
end
