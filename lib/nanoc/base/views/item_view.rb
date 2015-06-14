module Nanoc
  class ItemView
    include Nanoc::DocumentViewMixin

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
      reps.fetch(params.fetch(:rep, :default)).compiled_content(params)
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
      reps.fetch(params.fetch(:rep, :default)).path(params)
    end

    # Returns the children of this item. For items with identifiers that have
    # extensions, returns an empty collection.
    #
    # @return [Enumerable<Nanoc::ItemView>]
    def children
      unwrap.children.map { |i| Nanoc::ItemView.new(i) }
    end

    # Returns the parent of this item, if one exists. For items with identifiers
    # that have extensions, returns nil.
    #
    # @return [Nanoc::ItemView] if the item has a parent
    #
    # @return [nil] if the item has no parent
    def parent
      unwrap.parent && Nanoc::ItemView.new(unwrap.parent)
    end

    # @return [Boolean] True if the item is binary, false otherwise
    def binary?
      unwrap.content.binary?
    end

    # Returns the representations of this item.
    #
    # @return [Nanoc::ItemRepCollectionView]
    def reps
      Nanoc::ItemRepCollectionView.new(unwrap.reps)
    end

    # @api private
    def raw_filename
      unwrap.content.filename
    end
  end
end
