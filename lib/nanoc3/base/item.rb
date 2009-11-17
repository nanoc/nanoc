# encoding: utf-8

module Nanoc3

  # Nanoc3::Item represents a compileable item in a site. It has content and
  # attributes, as well as an identifier. It can also store the modification
  # time to speed up compilation.
  class Item

    # The Nanoc3::Site this item belongs to.
    attr_accessor :site

    # A hash containing this item's attributes.
    attr_accessor :attributes

    # This item's identifier.
    attr_accessor :identifier

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
    attr_accessor :outdated_due_to_dependencies

    # @param [String] raw_content The uncompiled item content.
    #
    # @param [Hash] attributes A hash containing this item's attributes.
    #
    # @param [String] identifier This item's identifier.
    #
    # @param [String, nil] mtime The time when this item was last modified.
    def initialize(raw_content, attributes, identifier, mtime=nil)
      @raw_content  = raw_content
      @attributes   = attributes.symbolize_keys
      @identifier   = identifier.cleaned_identifier
      @mtime        = mtime

      @parent       = nil
      @children     = []

      @reps         = []
    end

    # Returns the rep with the given name.
    #
    # @param [Symbol] rep_name The name of the representation to return.
    #
    # @return [Nanoc3::ItemRep] The representation with the given name.
    def rep(rep_name)
      @reps.find { |r| r.name == rep_name }
    end

    # Returns the compiled content from a given representation and a given
    # snapshot. This is a convenience method that makes fetching compiled
    # content easier.
    #
    # @option params [String] :rep (:default) The name of the representation
    #   from which the compiled content should be fetched. By default, the
    #   compiled content will be fetched from the default representation.
    #
    # @option params [String] :snapshot (:last) The name of the snapshot from
    #   which to fetch the compiled content. By default, the fully compiled
    #   content will be fetched, with all filters and layouts applied--not the
    #   pre-layout content.
    def compiled_content(params={})
      rep_name      = params[:rep]      || :default
      snapshot_name = params[:snapshot] || :last

      # Get rep
      rep = reps.find { |r| r.name == rep_name }
      if rep.nil?
        raise Nanoc3::Errors::Generic,
          "No rep named #{rep_name.inspect} was found."
      end

      # Get rep's content
      rep.content_at_snapshot(snapshot_name)
    end

    # Requests the attribute with the given key.
    #
    # @param [Symbol] key The name of the attribute to fetch.
    #
    # @return [Object] The value of the requested attribute.
    def [](key)
      Nanoc3::NotificationCenter.post(:visit_started, self)
      Nanoc3::NotificationCenter.post(:visit_ended,   self)

      @attributes[key]
    end

    # Sets the attribute with the given key to the given value.
    #
    # @param [Symbol] key The name of the attribute to set.
    #
    # @param [Object] value The value of the attribute to set.
    def []=(key, value)
      @attributes[key] = value
    end

    # @return [Boolean] true if any reps are outdated; false otherwise.
    def outdated?
      @reps.any? { |r| r.outdated? }
    end

    # Alias for #outdated_due_to_dependencies.
    def outdated_due_to_dependencies?
      self.outdated_due_to_dependencies
    end

    def inspect
      "<#{self.class}:0x#{self.object_id.to_s(16)} identifier=#{self.identifier}>"
    end

  end

end
