# encoding: utf-8

module Nanoc::Helpers

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
    #   with the item itself
    def breadcrumbs_trail
      trail      = []

      identifier = @item.identifier
      loop do
        trail.unshift(@items[identifier])
        identifier = identifier.parent
        break if identifier.nil?
      end

      trail
    end

  end

end
