module Nanoc

  # Nanoc::AssetDefaults represent the default attributes for all assets in
  # the site. If a specific asset attribute is requested, but not found, then
  # the asset defaults will be queried for this attribute. (If the attribute
  # doesn't even exist in the asset defaults, hardcoded defaults will be
  # used.)
  class AssetDefaults < Defaults

  end

end
