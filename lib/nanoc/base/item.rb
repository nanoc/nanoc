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

    # Returns the attribute with the given name.
    def attribute_named(name)
      Nanoc::NotificationCenter.post(:visit_started, self)
      Nanoc::NotificationCenter.post(:visit_ended,   self)

      @attributes[name]
    end

    # Returns a proxy (Nanoc::ItemProxy) for this item.
    def to_proxy
      @proxy ||= ItemProxy.new(self)
    end

  end

end
