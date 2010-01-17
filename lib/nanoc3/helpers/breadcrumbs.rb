# encoding: utf-8

module Nanoc3::Helpers

  # Provides support for breadcrumbs, which allow the user to go up in the
  # page hierarchy.
  module Breadcrumbs

    # Creates a breadcrumb trail leading from the current item to its parent,
    # to its parent’s parent, etc, until the root item is reached. This
    # function expects that each intermediate item exist; for example, if
    # there is no `/foo/` item, breadcrumbs for a `/foo/bar/` item cannot not
    # be calculated.
    #
    # @return [Array] The breadcrumbs, starting with the root item and ending
    #   with the item itself
    def breadcrumbs_trail
      trail = [] 
      item = @item 

      begin
        trail.unshift(item) 
        item = item.parent 
      end until item.nil?

      trail
    end

  end

end
