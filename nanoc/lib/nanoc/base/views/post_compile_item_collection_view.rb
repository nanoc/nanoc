# frozen_string_literal: true

module Nanoc
  module Base
    class PostCompileItemCollectionView < Nanoc::Base::IdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Base::PostCompileItemView
      end
    end
  end
end
