module Nanoc::Helpers
  # Provides functionality for fetching the children and the parent of a given
  # item. This works for both full identifiers and legacy identifiers.
  module ChildParent
    # Returns the parent of the given item.
    #
    # For items with legacy identifiers, the parent is the item where the
    # identifier contains one less component than the identifier of the given
    # item. For # example, the parent of the “/projects/nanoc/” item is the
    # “/projects/” item.
    #
    # For items with full identifiers, the parent is the item where the
    # identifier contains one less component than the identifier of the given
    # item, and ends with any extension. For example, the parent of the
    # “/projects/nanoc.md” item could be the “/projects.md” item, or the
    # “/projects.html” item, etc. Note that the parent is ambiguous for items
    # that have a full identifier; only the first candidate parent item will be
    # returned.
    def parent_of(item)
      if item.identifier.legacy?
        item.parent
      else
        path_without_last_component = item.identifier.to_s.sub(/[^\/]+$/, '').chop
        @items[path_without_last_component + '.*']
      end
    end

    # Returns the children of the given item.
    #
    # For items with legacy identifiers, the children are the items where the
    # identifier contains one more component than the identifier of the given
    # item. For example, the children of the “/projects/” item could be
    # “/projects/nanoc/” and “/projects/cri/”, but not “/about/” nor
    # “/projects/nanoc/history/”.
    #
    # For items with full identifiers, the children are the item where the
    # identifier starts with the identifier of the given item, minus the
    # extension, followed by a slash. For example, the children of the
    # “/projects.md” item could be the “/projects/nanoc.md” and
    # “/projects/cri.adoc” items , but not “/about.md” nor
    # “/projects/nanoc/history.md”.
    def children_of(item)
      if item.identifier.legacy?
        item.children
      else
        pattern = item.identifier.without_ext + '/*'
        @items.find_all(pattern)
      end
    end
  end
end
