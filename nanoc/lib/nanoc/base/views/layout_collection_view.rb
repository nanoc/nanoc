# frozen_string_literal: true

module Nanoc
  module Base
    class LayoutCollectionView < ::Nanoc::Base::IdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Base::LayoutView
      end
    end
  end
end
