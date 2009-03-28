module Nanoc3

  class AssetRep < Nanoc3::ItemRep

    # For compatibility
    alias_method :asset, :item

    # Returns the type of this object.
    def type
      :asset_rep
    end

  end

end
