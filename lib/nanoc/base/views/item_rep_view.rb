module Nanoc
  class ItemRepView < ::Nanoc::View
    # @api private
    def initialize(item_rep, context)
      super(context)
      @item_rep = item_rep
    end

    # @api private
    def unwrap
      @item_rep
    end

    # @see Object#==
    def ==(other)
      other.respond_to?(:item) && other.respond_to?(:name) && item == other.item && name == other.name
    end

    # @see Object#eql?
    def eql?(other)
      other.is_a?(self.class) &&
        item.eql?(other.item) &&
        name.eql?(other.name)
    end

    # @see Object#hash
    def hash
      self.class.hash ^ item.identifier.hash ^ name.hash
    end

    # @return [Symbol]
    def name
      @item_rep.name
    end

    # Returns the compiled content.
    #
    # @param [String] snapshot The name of the snapshot from which to
    #   fetch the compiled content. By default, the returned compiled content
    #   will be the content compiled right before the first layout call (if
    #   any).
    #
    # @return [String] The content at the given snapshot.
    def compiled_content(snapshot: nil)
      @context.dependency_tracker.bounce(unwrap.item, compiled_content: true)
      @context.snapshot_repo.compiled_content(rep: unwrap, snapshot: snapshot)
    end

    def snapshot?(name)
      @context.dependency_tracker.bounce(unwrap.item, compiled_content: true)
      @item_rep.snapshot?(name)
    end

    # Returns the item rep’s path, as used when being linked to. It starts
    # with a slash and it is relative to the output directory. It does not
    # include the path to the output directory. It will not include the
    # filename if the filename is an index filename.
    #
    # @param [Symbol] snapshot The snapshot for which the path should be
    #   returned.
    #
    # @return [String] The item rep’s path.
    def path(snapshot: :last)
      @context.dependency_tracker.bounce(unwrap.item, path: true)
      @item_rep.path(snapshot: snapshot)
    end

    # Returns the item that this item rep belongs to.
    #
    # @return [Nanoc::ItemWithRepsView]
    def item
      Nanoc::ItemWithRepsView.new(@item_rep.item, @context)
    end

    # @api private
    def raw_path(snapshot: :last)
      @context.dependency_tracker.bounce(unwrap.item, path: true)
      @item_rep.raw_path(snapshot: snapshot)
    end

    # @api private
    def binary?
      @context.snapshot_repo.raw_compiled_content(rep: unwrap, snapshot: :last).binary?
    end

    def inspect
      "<#{self.class} item.identifier=#{item.identifier} name=#{name}>"
    end
  end
end
