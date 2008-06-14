module Nanoc

  # Nanoc::AssetDefaults represent the default attributes for all assets in
  # the site. If a specific asset attribute is requested, but not found, then
  # the asset defaults will be queried for this attribute. (If the attribute
  # doesn't even exist in the asset defaults, hardcoded defaults will be
  # used.)
  class AssetDefaults < Defaults

    # Saves the asset defaults in the database, creating it if it doesn't
    # exist yet or updating it if it already exists. Tells the site's data
    # source to save the asset defaults.
    def save
      @site.data_source.loading do
        @site.data_source.save_asset_defaults(self)
      end
    end

  end

end
