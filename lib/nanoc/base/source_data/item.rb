module Nanoc::Int
  # @api private
  class Item < ::Nanoc::Int::Document
    # @return [Array<Nanoc::Int::ItemRep>] This item’s list of item reps
    attr_reader :reps

    # @return [String] The filename pointing to the file containing this
    #   item’s content
    attr_reader :raw_filename

    # @return [Nanoc::Int::Site] The site this item belongs to
    attr_accessor :site

    # @return [Nanoc::Int::Item, nil] The parent item of this item. This can be
    #   nil even for non-root items.
    attr_accessor :parent

    # @return [Array<Nanoc::Int::Item>] The child items of this item
    attr_accessor :children

    # Creates a new item with the given content or filename, attributes and
    # identifier.
    #
    # @param [String] raw_content_or_raw_filename The uncompiled item content
    #   (if it is a textual item) or the path to the filename containing the
    #   content (if it is a binary item).
    #
    # @param [Hash] attributes A hash containing this item's attributes.
    #
    # @param [String] identifier This item's identifier.
    #
    # @param [Hash] params Extra parameters.
    #
    # @option params [Symbol, nil] :binary (true) Whether or not this item is
    #   binary
    def initialize(raw_content_or_raw_filename, attributes, identifier, params = {})
      # Parse params
      params = params.merge(binary: false) unless params.key?(:binary)

      if raw_content_or_raw_filename.nil?
        raise "attempted to create an item with no content/filename (identifier #{identifier})"
      end

      # Get type and raw content or raw filename
      @is_binary = params[:binary]
      if @is_binary
        @raw_filename = raw_content_or_raw_filename
      else
        @raw_filename = attributes[:content_filename]
        @raw_content  = raw_content_or_raw_filename
      end

      # Get rest of params
      @attributes   = attributes.__nanoc_symbolize_keys_recursively
      @identifier   = Nanoc::Identifier.from(identifier)

      # Set mtime
      @attributes.merge!(mtime: params[:mtime]) if params[:mtime]

      @parent       = nil
      @children     = []

      @reps         = []
    end

    # Returns the rep with the given name.
    #
    # @param [Symbol] rep_name The name of the representation to return
    #
    # @return [Nanoc::Int::ItemRep] The representation with the given name
    def rep_named(rep_name)
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
    # @option params [String] :snapshot The name of the snapshot from which to
    #   fetch the compiled content. By default, the returned compiled content
    #   will be the content compiled right before the first layout call (if
    #   any).
    #
    # @return [String] The compiled content of the given rep (or the default
    #   rep if no rep is specified) at the given snapshot (or the default
    #   snapshot if no snapshot is specified)
    #
    # @see ItemRep#compiled_content
    def compiled_content(params = {})
      # Get rep
      rep_name = params[:rep] || :default
      rep = reps.find { |r| r.name == rep_name }
      if rep.nil?
        raise Nanoc::Int::Errors::Generic,
          "No rep named #{rep_name.inspect} was found."
      end

      # Get rep's content
      rep.compiled_content(params)
    end

    # Returns the path from a given representation. This is a convenience
    # method that makes fetching the path of a rep easier.
    #
    # @option params [String] :rep (:default) The name of the representation
    #   from which the path should be fetched. By default, the path will be
    #   fetched from the default representation.
    #
    # @return [String] The path of the given rep ( or the default rep if no
    #   rep is specified)
    def path(params = {})
      rep_name = params[:rep] || :default

      # Get rep
      rep = reps.find { |r| r.name == rep_name }
      if rep.nil?
        raise Nanoc::Int::Errors::Generic,
          "No rep named #{rep_name.inspect} was found."
      end

      # Get rep's path
      rep.path
    end

    # @return [Boolean] True if the item is binary; false if it is not
    def binary?
      @is_binary
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [:item, identifier.to_s]
    end

    # Prevents all further modifications to its attributes.
    #
    # @return [void]
    def freeze
      attributes.__nanoc_freeze_recursively
      children.freeze
      identifier.freeze
      raw_filename.freeze if raw_filename
      raw_content.freeze  if raw_content
    end

    # @api private
    def forced_outdated=(bool)
      @forced_outdated = bool
    end

    # @api private
    def forced_outdated?
      @forced_outdated || false
    end
  end
end
