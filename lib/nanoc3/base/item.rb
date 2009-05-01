module Nanoc3

  # Nanoc3::Item is represents all compileable items in a site. It has content
  # and attributes, as well as an identifier. It can also store the
  # modification time to speed up compilation.
  #
  # An item is observable. The following events will be notified:
  #
  # * :visit_started
  # * :visit_ended
  #
  # Each item has a list of item representations or reps (Nanoc3::ItemRep);
  # compiling an item actually compiles all of its representations.
  class Item

    # The Nanoc3::Site this item belongs to.
    attr_accessor :site

    # A hash containing this item's attributes.
    attr_accessor :attributes

    # This item's identifier.
    attr_reader   :identifier

    # The time when this item was last modified.
    attr_reader   :mtime

    # This item's list of item representations.
    attr_reader   :reps

    # This item's raw, uncompiled content.
    attr_reader   :content

    # The parent item of this item. This can be nil even for non-root items.
    attr_accessor :parent

    # The child items of this item.
    attr_accessor :children

    # Creates a new item.
    #
    # +content+:: The uncompiled item content.
    #
    # +attributes+:: A hash containing this item's attributes.
    #
    # +identifier+:: This item's identifier.
    #
    # +mtime+:: The time when this item was last modified.
    def initialize(content, attributes, identifier, mtime=nil)
      @content    = content
      @attributes = attributes.clean
      @identifier = identifier.cleaned_identifier
      @mtime      = mtime

      @parent     = nil
      @children   = []

      @reps       = []
    end

    # Requests the attribute with the given key.
    def [](key)
      Nanoc3::NotificationCenter.post(:visit_started, self)
      Nanoc3::NotificationCenter.post(:visit_ended,   self)

      @attributes[key]
    end

    # Sets the attribute with the given key to the given value.
    def []=(key, value)
      @attributes[key] = value
    end

    def inspect
      "<#{self.class} identifier=#{self.identifier}>"
    end

  end

end
