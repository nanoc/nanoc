# encoding: utf-8

module Nanoc3::Helpers

  # Provides support for breadcrumbs, which allow the user to go up in the
  # page hierarchy.
  module Breadcrumbs

    # Creates a breadcrumb trail leading from the current item to its parent,
    # to its parent’s parent, etc, until the root item is reached. This
    # function does not require that each intermediate item exist; for
    # example, if there is no `/foo/` item, breadcrumbs for a `/foo/bar/` item
    # will contain a `nil` element.
    #
    # @return [Array] The breadcrumbs, starting with the root item and ending
    # with the item itself
    def breadcrumbs_trail
      trail = []
      current_identifier = @item.identifier

      loop do
        item = @items.find { |i| i.identifier == current_identifier }
        trail.unshift(item)
        break if current_identifier == '/'
        current_identifier = current_identifier.sub(/[^\/]+\/$/, '')
      end

      trail
    end

  end

end
