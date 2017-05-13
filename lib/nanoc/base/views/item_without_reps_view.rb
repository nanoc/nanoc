# frozen_string_literal: true

module Nanoc
  class ItemWithoutRepsView < ::Nanoc::View
    include Nanoc::DocumentViewMixin

    # Returns the children of this item. For items with identifiers that have
    # extensions, returns an empty collection.
    #
    # @return [Enumerable<Nanoc::ItemWithRepsView>]
    def children
      unless unwrap.identifier.legacy?
        raise Nanoc::Int::Errors::CannotGetParentOrChildrenOfNonLegacyItem.new(unwrap.identifier)
      end

      children_pattern = Nanoc::Int::Pattern.from(unwrap.identifier.to_s + '*/')
      children = @context.items.select { |i| children_pattern.match?(i.identifier) }

      children.map { |i| self.class.new(i, @context) }.freeze
    end

    # Returns the parent of this item, if one exists. For items with identifiers
    # that have extensions, returns nil.
    #
    # @return [Nanoc::ItemWithRepsView] if the item has a parent
    #
    # @return [nil] if the item has no parent
    def parent
      unless unwrap.identifier.legacy?
        raise Nanoc::Int::Errors::CannotGetParentOrChildrenOfNonLegacyItem.new(unwrap.identifier)
      end

      parent_identifier = '/' + unwrap.identifier.components[0..-2].join('/') + '/'
      parent_identifier = '/' if parent_identifier == '//'

      parent = @context.items[parent_identifier]

      parent && self.class.new(parent, @context)
    end

    # @return [Boolean] True if the item is binary, false otherwise
    def binary?
      unwrap.content.binary?
    end

    # @api private
    def raw_filename
      unwrap.content.filename
    end
  end
end
