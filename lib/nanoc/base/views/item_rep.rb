module Nanoc
  class ItemRepView
    # @api private
    def initialize(item_rep)
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

    # Returns the compiled content.
    #
    # @option params [String] :snapshot The name of the snapshot from which to
    #   fetch the compiled content. By default, the returned compiled content
    #   will be the content compiled right before the first layout call (if
    #   any).
    #
    # @return [String] The content at the given snapshot.
    def compiled_content(params = {})
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap.item)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap.item)

      @item_rep.compiled_content(params)
    end

    # Returns the item rep’s path, as used when being linked to. It starts
    # with a slash and it is relative to the output directory. It does not
    # include the path to the output directory. It will not include the
    # filename if the filename is an index filename.
    #
    # @option params [Symbol] :snapshot (:last) The snapshot for which the
    #   path should be returned.
    #
    # @return [String] The item rep’s path.
    def path(params = {})
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap.item)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap.item)

      @item_rep.path(params)
    end

    # Returns the item that this item rep belongs to.
    #
    # @return [Nanoc::ItemView]
    def item
      Nanoc::ItemView.new(@item_rep.item)
    end

    # @api private
    def raw_path(params = {})
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap.item)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap.item)

      @item_rep.raw_path(params)
    end

    # @api private
    def binary?
      @item_rep.binary?
    end
  end
end
