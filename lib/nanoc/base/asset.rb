module Nanoc

  # A Nanoc::Asset represents an asset in a nanoc site. It has content and
  # attributes, as well as a path. It can also store the modification time to
  # speed up compilation.
  #
  # An asset is observable. The following events will be notified:
  #
  # * :visit_started
  # * :visit_ended
  #
  # Each asset has a list of asset representations or reps (Nanoc::AssetRep);
  # compiling an asset actually compiles all of its assets.
  class Asset < Nanoc::Item

    # Builds the individual asset representations (Nanoc::AssetRep) for this
    # asset.
    def build_reps
      super(AssetRep)
    end

    # Returns the type of this object.
    def type
      :asset
    end

    # Returns a proxy (Nanoc::AssetProxy) for this asset.
    def to_proxy
      super(AssetProxy)
    end

  end

end
