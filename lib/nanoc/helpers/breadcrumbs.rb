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
      breadcrumbs_for_identifier(@item.identifier)
    end

    def item_with_identifier(identifier)
      @identifier_cache ||= {}
      @identifier_cache[identifier] ||= begin
        @items.find { |i| i.identifier == identifier }
      end
    end

    def breadcrumbs_for_identifier(identifier)
      @breadcrumbs_cache ||= {}
      @breadcrumbs_cache[identifier] ||= begin
        head = (identifier == '/' ? [] :  breadcrumbs_for_identifier(identifier.sub(/[^\/]+\/$/, '')) )
        tail = [ item_with_identifier(identifier) ]

        head + tail
      end
    end

  end

end
