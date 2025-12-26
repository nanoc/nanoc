# frozen_string_literal: true

module Nanoc
  module Core
    class BasicItemView < ::Nanoc::Core::View
      include Nanoc::Core::DocumentViewMixin

      # Returns the children of this item. For items with identifiers that have
      # extensions, returns an empty collection.
      #
      # @return [Enumerable<Nanoc::Core::CompilationItemView>]
      def children
        unless _unwrap.identifier.legacy?
          raise Nanoc::Core::Errors::CannotGetParentOrChildrenOfNonLegacyItem.new(_unwrap.identifier)
        end

        children_pattern = Nanoc::Core::Pattern.from(_unwrap.identifier.to_s + '*/')
        children = @context.items.select { |i| children_pattern.match?(i.identifier) }

        children.map { |i| self.class.new(i, @context) }.freeze
      end

      # Returns the parent of this item, if one exists. For items with identifiers
      # that have extensions, returns nil.
      #
      # @return [Nanoc::Core::CompilationItemView] if the item has a parent
      #
      # @return [nil] if the item has no parent
      def parent
        unless _unwrap.identifier.legacy?
          raise Nanoc::Core::Errors::CannotGetParentOrChildrenOfNonLegacyItem.new(_unwrap.identifier)
        end

        parent_identifier = '/' + _unwrap.identifier.components[0..-2].join('/') + '/'
        parent_identifier = '/' if parent_identifier == '//'

        parent = @context.items.object_with_identifier(parent_identifier)

        parent && self.class.new(parent, @context)
      end

      # @return [Boolean] True if the item is binary, false otherwise
      def binary?
        _unwrap.content.binary?
      end

      # @return [String, nil] The path to the file containing the uncompiled content of this item.
      def raw_filename
        @context.dependency_tracker.bounce(_unwrap, raw_content: true)
        _unwrap.content.filename
      end
    end
  end
end
