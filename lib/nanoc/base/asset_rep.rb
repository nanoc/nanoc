module Nanoc

  class AssetRep < Nanoc::ItemRep

    # For compatibility
    alias_method :asset, :item

    # Returns the type of this object.
    def type
      :asset_rep
    end

  end

end
