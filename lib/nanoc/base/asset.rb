module Nanoc

  # A Nanoc::Asset represents an asset in a nanoc site. It has a file object
  # (File instance) and attributes, as well as a path. It can also store the
  # modification time to speed up compilation.
  #
  # Each asset has a list of asset representations or reps (Nanoc::AssetRep);
  # compiling an asset actually compiles all of its assets.
  class Asset

    # Defaults values for assets.
    DEFAULTS = {
      :extension  => 'dat',
      :binary     => true,
      :filters    => []
    }

    # The Nanoc::Site this asset belongs to.
    attr_accessor :site

    # This assets's file.
    attr_reader   :file

    # A hash containing this asset's attributes.
    attr_accessor :attributes

    # This asset's path.
    attr_reader   :path

    # The time when this asset was last modified.
    attr_reader   :mtime

    # This asset's list of asset representations.
    attr_reader   :reps

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
      # Get list of rep names
      rep_names_default = (@site.asset_defaults.attributes[:reps] || {}).keys
      rep_names_this    = (@attributes[:reps] || {}).keys + [ :default ]
      rep_names         = rep_names_default | rep_names_this

      # Get list of reps
      reps = rep_names.inject({}) do |memo, rep_name|
        rep = (@attributes[:reps] || {})[rep_name]
        is_bad = (@attributes[:reps] || {}).has_key?(rep_name) && rep.nil?
        is_bad ? memo : memo.merge(rep_name => rep || {})
      end

      # Build reps
      @reps = []
      reps.each_pair do |name, attrs|
        @reps << AssetRep.new(self, attrs, name)
      end
    end

    # Returns a proxy (Nanoc::AssetProxy) for this asset.
    def to_proxy
      @proxy ||= AssetProxy.new(self)
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return @site.asset_defaults.attributes[name] if @site.asset_defaults.attributes.has_key?(name)
      return DEFAULTS[name]
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
