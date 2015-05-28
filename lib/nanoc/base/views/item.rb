module Nanoc
  class ItemView
    # @api private
    NONE = Object.new

    # @api private
    def initialize(item)
      @item = item
    end

    # @api private
    def unwrap
      @item
    end

    # @see Object#==
    def ==(other)
      identifier == other.identifier
    end
    alias_method :eql?, :==

    # @see Object#hash
    def hash
      self.class.hash ^ identifier.hash
    end

    # @return [Nanoc::Identifier]
    def identifier
      @item.identifier
    end

    # @see Hash#fetch
    def fetch(key, fallback=NONE, &block)
      res = @item[key] # necessary for dependency tracking

      if @item.attributes.key?(key)
        res
      else
        if !fallback.equal?(NONE)
          fallback
        elsif block_given?
          yield(key)
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end
    end

    # @see Hash#key?
    def key?(key)
      _res = @item[key] # necessary for dependency tracking
      @item.attributes.key?(key)
    end

    # @see Hash#[]
    def [](key)
      @item[key]
    end

    # Returns the compiled content.
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
    # @return [String] The content of the given rep at the given snapshot.
    def compiled_content(params = {})
      @item.compiled_content(params)
    end

    # Returns the item path, as used when being linked to. It starts
    # with a slash and it is relative to the output directory. It does not
    # include the path to the output directory. It will not include the
    # filename if the filename is an index filename.
    #
    # @option params [String] :rep (:default) The name of the representation
    #   from which the path should be fetched. By default, the path will be
    #   fetched from the default representation.
    #
    # @option params [Symbol] :snapshot (:last) The snapshot for which the
    #   path should be returned.
    #
    # @return [String] The item’s path.
    def path(params = {})
      @item.path(params)
    end

    # Returns the children of this item. For items with identifiers that have
    # extensions, returns an empty collection.
    #
    # @return [Enumerable<Nanoc::ItemView>]
    def children
      @item.children.map { |i| Nanoc::ItemView.new(i) }
    end

    # Returns the parent of this item, if one exists. For items with identifiers
    # that have extensions, returns nil.
    #
    # @return [Nanoc::ItemView] if the item has a parent
    #
    # @return [nil] if the item has no parent
    def parent
      @item.parent && Nanoc::ItemView.new(@item.parent)
    end

    # @return [Boolean] True if the item is binary, false otherwise
    def binary?
      @item.binary?
    end

    # For textual items, returns the raw (source) content of this item; for
    # binary items, returns `nil`.
    #
    # @return [String] if the item is textual
    #
    # @return [nil] if the item is binary
    def raw_content
      @item.raw_content
    end

    # Returns the representations of this item.
    #
    # @return [Enumerable<Nanoc::ItemRepView>]
    def reps
      @item.reps.map { |r| Nanoc::ItemRepView.new(r) }
    end

    # @api private
    def raw_filename
      @item.raw_filename
    end
  end
end
