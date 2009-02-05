module Nanoc

  # Nanoc::Item is the (abstract) superclass for any compileable item in a
  # site. Currently, there are only two subclasses, Nanoc::Page and
  # Nanoc::Asset.
  class Item

    # The Nanoc::Site this item belongs to.
    attr_accessor :site

    # A hash containing this item's attributes.
    attr_accessor :attributes

    # This item's path.
    attr_reader   :path

    # The time when this item was last modified.
    attr_reader   :mtime

    # This item's list of item representations.
    attr_reader   :reps

    # This item's raw, uncompiled content.
    attr_reader   :content

    # The parent item of this item. This can be nil even for non-root items.
    attr_accessor :parent

    # The child items of this page.
    attr_accessor :children

    # Creates a new item.
    #
    # +content+:: The uncompiled item content.
    #
    # +attributes+:: A hash containing this item's attributes.
    #
    # +path+:: This item's path.
    #
    # +mtime+:: The time when this item was last modified.
    def initialize(content, attributes, path, mtime=nil)
      @content    = content
      @attributes = attributes.clean
      @path       = path.cleaned_path
      @mtime      = mtime

      @parent     = nil
      @children   = []

      @reps       = []
    end

    # Builds the individual item representations (either Nanoc::PageRep or
    # Nanoc::AssetRep) for this item.
    def build_reps(klass, site_defaults)
      # Get list of rep names
      rep_names_default = (site_defaults.attributes[:reps] || {}).keys
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
        @reps << klass.new(self, attrs, name)
      end
    end

    # Returns the attribute with the given name.
    def attribute_named(name, site_defaults, defaults)
      return @attributes[name] if @attributes.has_key?(name)
      return site_defaults.attributes[name] if site_defaults.attributes.has_key?(name)
      return defaults[name]
    end

    # Returns a proxy (either Nanoc::PageProxy or Nanoc::AssetProxy) for this
    # item.
    def to_proxy(klass)
      @proxy ||= klass.new(self)
    end

  end

end
