module Nanoc::Helpers
  # Provides support for breadcrumbs, which allow the user to go up in the
  # page hierarchy.
  module Breadcrumbs
    class CannotGetBreadcrumbsForNonLegacyItem < Nanoc::Int::Errors::Generic
      def initialize(identifier)
        super("You cannot build a breadcrumbs trail for an item that has a “full” identifier (#{identifier}). Doing so is only possible for items that have a legacy identifier.")
      end
    end

    # Creates a breadcrumb trail leading from the current item to its parent,
    # to its parent’s parent, etc, until the root item is reached. This
    # function does not require that each intermediate item exist; for
    # example, if there is no `/foo/` item, breadcrumbs for a `/foo/bar/` item
    # will contain a `nil` element.
    #
    # @return [Array] The breadcrumbs, starting with the root item and ending
    #   with the item itself
    def breadcrumbs_trail
      unless @item.identifier.legacy?
        raise CannotGetBreadcrumbsForNonLegacyItem.new(@item.identifier)
      end

      trail      = []
      idx_start  = 0

      loop do
        idx = @item.identifier.to_s.index('/', idx_start)
        break if idx.nil?

        idx_start = idx + 1
        identifier = @item.identifier.to_s[0..idx]
        trail << @items[identifier]
      end

      trail
    end
  end
end
