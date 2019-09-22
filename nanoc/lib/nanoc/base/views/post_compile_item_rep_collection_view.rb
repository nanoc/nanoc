# frozen_string_literal: true

module Nanoc
  module Base
    class PostCompileItemRepCollectionView < Nanoc::Base::BasicItemRepCollectionView
      # @api private
      def view_class
        Nanoc::Base::PostCompileItemRepView
      end
    end
  end
end
