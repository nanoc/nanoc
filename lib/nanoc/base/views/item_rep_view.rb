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
      item.identifier == other.item.identifier && name == other.name
    end
    alias_method :eql?, :==

    # @see Object#hash
    def hash
      self.class.hash ^ item.identifier.hash ^ name.hash
    end

    # @return [Symbol]
    def name
      @item_rep.name
    end

    # @return [Boolean]
    def modified
      @item_rep.modified
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
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap.item)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap.item)

      @item_rep.compiled_content(snapshot: snapshot)
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
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap.item)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap.item)

      @item_rep.path(snapshot: snapshot)
    end

    # Returns the item that this item rep belongs to.
    #
    # @return [Nanoc::ItemView]
    def item
      Nanoc::ItemView.new(@item_rep.item, @context)
    end

    # @api private
    def raw_path(snapshot: :last)
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap.item)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap.item)

      @item_rep.raw_path(snapshot: snapshot)
    end

    # @api private
    def binary?
      @item_rep.binary?
    end
  end
end
