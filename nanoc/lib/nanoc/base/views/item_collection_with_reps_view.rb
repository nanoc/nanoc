# frozen_string_literal: true

module Nanoc
  module Base
    class ItemCollectionWithRepsView < ::Nanoc::Base::IdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Base::CompilationItemView
      end
    end
  end
end
