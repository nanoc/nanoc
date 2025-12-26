# frozen_string_literal: true

module Nanoc
  module Core
    class ItemCollectionWithRepsView < ::Nanoc::Core::IdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Core::CompilationItemView
      end
    end
  end
end
