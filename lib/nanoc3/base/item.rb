# encoding: utf-8

module Nanoc3

  # Represents a compileable item in a site. It has content and attributes, as
  # well as an identifier (which starts and ends with a slash). It can also
  # store the modification time to speed up compilation.
  class Item

    # @return [Nanoc3::Site] The site this item belongs to
    attr_accessor :site

    # @return [Hash] This item's attributes
    attr_accessor :attributes

    # A string that uniquely identifies an item in a site.
    #
    # Identifiers start and end with a slash. They are comparable to paths on
    # the filesystem, with the difference that file system paths usually do
    # not have a trailing slash. The item hierarchy (parent and children of
    # items) is determined by the item identifier.
    #
    # The root page (the home page) has the identifier “/”, which means
    # that it is the ancestor of all other items.
    #
    # @return [String] This item's identifier
    attr_accessor :identifier

    # @return [Time] The time when this item was last modified
    attr_reader   :mtime

    # @return [Array<Nanoc3::ItemRep>] This item’s list of item reps
    attr_reader   :reps

    # @return [String] This item's raw, uncompiled content of this item (only
    # available for textual items)
    attr_reader   :raw_content

    # @return [String] The filename pointing to the file containing this
    # item’s content (only available for binary items)
    attr_reader   :raw_filename

    # @return [Nanoc3::Item, nil] The parent item of this item. This can be
    # nil even for non-root items.
    attr_accessor :parent

    # @return [Array<Nanoc3::Item>] The child items of this item
    attr_accessor :children

    # @return [Boolean] Whether or not this item is outdated because of its
    # dependencies are outdated
    attr_accessor :outdated_due_to_dependencies
    alias_method :outdated_due_to_dependencies?, :outdated_due_to_dependencies

    # Creates a new item with the given content or filename, attributes and
    # identifier.
    #
    # Note that the API in 3.1 has changed a bit since 3.0; the API remains
    # backwards compatible, however. Passing the modification time as the 4th
    # parameter is deprecated; pass it as the `:mtime` method option instead.
    #
    # @param [String] raw_content_or_raw_filename The uncompiled item content
    # (if it is a textual item) or the path to the filename containing the
    # content (if it is a binary item).
    #
    # @param [Hash] attributes A hash containing this item's attributes.
    #
    # @param [String] identifier This item's identifier.
    #
    # @param [Time, Hash, nil] params_or_mtime Extra parameters for the item,
    # or the time when this item was last modified (deprecated).
    #
    # @option params_or_mtime [Time, nil] :mtime (nil) The time when this item
    # was last modified
    #
    # @option params_or_mtime [Symbol, nil] :binary (true) Whether or not this
    # item is binary
    def initialize(raw_content_or_raw_filename, attributes, identifier, params_or_mtime=nil)
      # Get params and mtime
      # TODO [in nanoc 4.0] clean this up
      if params_or_mtime.nil? || params_or_mtime.is_a?(Time)
        params = {}
        @mtime = params_or_mtime
      elsif params_or_mtime.is_a?(Hash)
        params = params_or_mtime
        @mtime = params[:mtime]
      end

      # Get type and raw content or raw filename
      @is_binary = params.has_key?(:binary) ? params[:binary] : false
      if @is_binary
        @raw_filename = raw_content_or_raw_filename
      else
        @raw_content  = raw_content_or_raw_filename
      end

      # Get rest of params
      @attributes   = attributes.symbolize_keys
      @identifier   = identifier.cleaned_identifier

      @parent       = nil
      @children     = []

      @reps         = []
    end

    # Returns the rep with the given name.
    #
    # @param [Symbol] rep_name The name of the representation to return
    #
    # @return [Nanoc3::ItemRep] The representation with the given name
    def rep_named(rep_name)
      @reps.find { |r| r.name == rep_name }
    end

    # Returns the compiled content from a given representation and a given
    # snapshot. This is a convenience method that makes fetching compiled
    # content easier.
    #
    # @option params [String] :rep (:default) The name of the representation
    # from which the compiled content should be fetched. By default, the
    # compiled content will be fetched from the default representation.
    #
    # @option params [String] :snapshot The name of the snapshot from which to
    # fetch the compiled content. By default, the returned compiled content
    # will be the content compiled right before the first layout call (if
    # any).
    #
    # @return [String] The compiled content of the given rep (or the default
    # rep if no rep is specified) at the given snapshot (or the default
    # snapshot if no snapshot is specified)
    #
    # @see ItemRep#compiled_content
    def compiled_content(params={})
      # Get rep
      rep_name = params[:rep] || :default
      rep = reps.find { |r| r.name == rep_name }
      if rep.nil?
        raise Nanoc3::Errors::Generic,
          "No rep named #{rep_name.inspect} was found."
      end

      # Get rep's content
      rep.compiled_content(params)
    end

    # Returns the path from a given representation. This is a convenience
    # method that makes fetching the path of a rep easier.
    #
    # @option params [String] :rep (:default) The name of the representation
    # from which the path should be fetched. By default, the path will be
    # fetched from the default representation.
    #
    # @return [String] The path of the given rep ( or the default rep if no
    # rep is specified)
    def path(params={})
      rep_name = params[:rep] || :default

      # Get rep
      rep = reps.find { |r| r.name == rep_name }
      if rep.nil?
        raise Nanoc3::Errors::Generic,
          "No rep named #{rep_name.inspect} was found."
      end

      # Get rep's path
      rep.path
    end

    # Requests the attribute with the given key.
    #
    # @param [Symbol] key The name of the attribute to fetch
    #
    # @return [Object] The value of the requested attribute
    def [](key)
      Nanoc3::NotificationCenter.post(:visit_started, self)
      Nanoc3::NotificationCenter.post(:visit_ended,   self)

      @attributes[key]
    end

    # Sets the attribute with the given key to the given value.
    #
    # @param [Symbol] key The name of the attribute to set
    #
    # @param [Object] value The value of the attribute to set
    def []=(key, value)
      @attributes[key] = value
    end

    # @return [Boolean] True if the item is binary; false if it is not
    def binary?
      !!@is_binary
    end

    # Determines whether this item (or rather, its reps) is outdated and
    # should be recompiled (or rather, its reps should be recompiled).
    #
    # @return [Boolean] true if any reps are outdated; false otherwise.
    def outdated?
      @reps.any? { |r| r.outdated? }
    end

    def inspect
      "<#{self.class}:0x#{self.object_id.to_s(16)} identifier=#{self.identifier} binary?=#{self.binary?}>"
    end

  end

end
