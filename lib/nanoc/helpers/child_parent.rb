# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#childparent
  module ChildParent
    def parent_of(item)
      if item.identifier.legacy?
        item.parent
      else
        path_without_last_component = item.identifier.to_s.sub(/[^\/]+$/, '').chop
        @items[path_without_last_component + '.*']
      end
    end

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
