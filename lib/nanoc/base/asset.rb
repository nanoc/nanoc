module Nanoc

  class Asset

    DEFAULTS = {
      :extension  => 'dat',
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

    def initialize(file, attributes, path, mtime=nil)
      # Set primary attributes
      @file           = file
      @attributes     = attributes.clean
      @path           = path.cleaned_path
      @mtime          = mtime

      # Not modified, not created by default
      @modified       = false
      @created        = false

      # Reset flags
      @filtered       = false
      @written        = false
    end

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

    def to_proxy
      @proxy ||= AssetProxy.new(self)
    end

    def outdated?
      # Outdated if we don't know
      return true if @mtime.nil?

      # Outdated if an asset rep is outdated
      return @reps.any? { |rep| rep.outdated? }
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return @site.asset_defaults.attributes[name] if @site.asset_defaults.attributes.has_key?(name)
      return DEFAULTS[name]
    end

    def compile
      # Compile all representations
      @reps.each { |r| r.compile }
    end

  end

end
