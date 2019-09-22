# frozen_string_literal: true

module Nanoc
  module Core
    class MutableLayoutCollectionView < Nanoc::Core::MutableIdentifiableCollectionView
      # @api private
      def view_class
        Nanoc::Core::MutableLayoutView
      end

      # Creates a new layout and adds it to the site’s collection of layouts.
      #
      # @param [String] content The layout content.
      #
      # @param [Hash] attributes A hash containing this layout's attributes.
      #
      # @param [Nanoc::Core::Identifier, String] identifier This layout's identifier.
      #
      # @return [self]
      def create(content, attributes, identifier)
        @objects = @objects.add(Nanoc::Core::Layout.new(content, attributes, identifier))
        self
      end
    end
  end
end
