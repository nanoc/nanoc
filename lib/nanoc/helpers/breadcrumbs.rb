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
