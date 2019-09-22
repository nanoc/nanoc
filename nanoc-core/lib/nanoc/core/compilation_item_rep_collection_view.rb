# frozen_string_literal: true

module Nanoc
  module Core
    class CompilationItemRepCollectionView < ::Nanoc::Core::BasicItemRepCollectionView
      # @api private
      def view_class
        Nanoc::Core::CompilationItemRepView
      end
    end
  end
end
