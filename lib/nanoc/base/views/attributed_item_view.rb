module Nanoc
  class AttributedItemView < Nanoc::ItemView
    include Nanoc::DocumentViewMixin

    def updated?
      false
    end
  end
end
