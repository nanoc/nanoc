module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#breadcrumbs
  module Breadcrumbs
    class CannotGetBreadcrumbsForNonLegacyItem < Nanoc::Int::Errors::Generic
      def initialize(identifier)
        super("You cannot build a breadcrumbs trail for an item that has a “full” identifier (#{identifier}). Doing so is only possible for items that have a legacy identifier.")
      end
    end

    # @return [Array]
    def breadcrumbs_trail
      unless @item.identifier.legacy?
        raise CannotGetBreadcrumbsForNonLegacyItem.new(@item.identifier)
      end

      # e.g. ['', '/foo', '/foo/bar']
      prefixes =
        item.identifier.components
        .inject(['']) { |acc, elem| acc + [acc.last + '/' + elem] }

      prefixes.map { |pr| @items[Nanoc::Identifier.new('/' + pr, type: :legacy)] }
    end
  end
end
