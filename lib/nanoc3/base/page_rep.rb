module Nanoc3

  class PageRep < Nanoc3::ItemRep

    # For compatibility
    alias_method :page, :item

    # Returns the type of this object.
    def type
      :page_rep
    end

  end

end
