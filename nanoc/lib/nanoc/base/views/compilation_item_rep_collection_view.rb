# frozen_string_literal: true

module Nanoc
  module Base
    class CompilationItemRepCollectionView < ::Nanoc::Base::BasicItemRepCollectionView
      # @api private
      def view_class
        Nanoc::Base::CompilationItemRepView
      end
    end
  end
end
