module Nanoc

  # A Nanoc::Asset represents an asset in a nanoc site. It has a file object
  # (File instance) and attributes, as well as a path. It can also store the
  # modification time to speed up compilation.
  #
  # An asset is observable. The following events will be notified:
  #
  # * :visit_started
  # * :visit_ended
  #
  # Each asset has a list of asset representations or reps (Nanoc::AssetRep);
  # compiling an asset actually compiles all of its assets.
  class Asset < Nanoc::Item

    # Defaults values for assets.
    DEFAULTS = {
      :extension  => 'dat',
      :filters    => []
    }

    # This assets's file.
    attr_reader   :file

    # Creates a new asset.
    #
    # +file+:: An instance of File representing the uncompiled asset.
    #
    # +attributes+:: A hash containing this asset's attributes.
    #
    # +path+:: This asset's path.
    #
    # +mtime+:: The time when this asset was last modified.
    def initialize(file, attributes, path, mtime=nil)
      # Set primary attributes
      @file           = file
      @attributes     = attributes.clean
      @path           = path.cleaned_path
      @mtime          = mtime
    end

    # Builds the individual asset representations (Nanoc::AssetRep) for this
    # asset.
    def build_reps
      super(AssetRep, @site.asset_defaults)
    end

    # Returns the type of this object.
    def type
      :asset
    end

    # Returns a proxy (Nanoc::AssetProxy) for this asset.
    def to_proxy
      super(AssetProxy)
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      Nanoc::NotificationCenter.post(:visit_started, self)
      Nanoc::NotificationCenter.post(:visit_ended,   self)

      super(name, @site ? @site.asset_defaults : nil, Nanoc::Asset::DEFAULTS)
    end

    # Saves the asset in the database, creating it if it doesn't exist yet or
    # updating it if it already exists. Tells the site's data source to save
    # the asset.
    def save
      @site.data_source.loading do
        @site.data_source.save_asset(self)
      end
    end

    # Moves the asset to a new path. Tells the site's data source to move the
    # asset.
    def move_to(new_path)
      @site.data_source.loading do
        @site.data_source.move_asset(self, new_path)
      end
    end

    # Deletes the asset. Tells the site's data source to delete the asset.
    def delete
      @site.data_source.loading do
        @site.data_source.delete_asset(self)
      end
    end

  end

end
