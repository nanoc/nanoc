# encoding: utf-8

module Nanoc3::Helpers

  # Nanoc3::Helpers::Breadcrumbs provides support for breadcrumbs, which allow
  # the user to go up in the page hierarchy.
  module Breadcrumbs

    # Returns the breadcrumbs trail as an array. Higher items (items that are
    # closer to the root) come before lower items.
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
