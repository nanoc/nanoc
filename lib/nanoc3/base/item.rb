# encoding: utf-8

module Nanoc3

  # Nanoc3::Item is represents all compileable items in a site. It has content
  # and attributes, as well as an identifier. It can also store the
  # modification time to speed up compilation.
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
    attr_reader   :raw_content

    # The parent item of this item. This can be nil even for non-root items.
    attr_accessor :parent

    # The child items of this item.
    attr_accessor :children

    # A boolean indicating whether or not this item is outdated because of its dependencies are outdated.
    attr_accessor :dependencies_outdated

    # Creates a new item.
    #
    # +raw_content+:: The uncompiled item content.
    #
    # +attributes+:: A hash containing this item's attributes.
    #
    # +identifier+:: This item's identifier.
    #
    # +mtime+:: The time when this item was last modified.
    def initialize(raw_content, attributes, identifier, mtime=nil)
      @raw_content  = raw_content
      @attributes   = attributes.symbolize_keys
      @identifier   = identifier.cleaned_identifier
      @mtime        = mtime

      @parent       = nil
      @children     = []

      @reps         = []
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

    # True if any reps are outdated; false otherwise.
    def outdated?
      @reps.any? { |r| r.outdated? }
    end

    # Alias for #dependencies_outdated.
    def dependencies_outdated?
      self.dependencies_outdated
    end

    def inspect
      "<#{self.class} identifier=#{self.identifier}>"
    end

  end

end
