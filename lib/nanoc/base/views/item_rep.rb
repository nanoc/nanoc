# encoding: utf-8

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
      @item_rep.path(params)
    end

    # Returns the item that this item rep belongs to.
    #
    # @return [Nanoc::ItemView]
    def item
      Nanoc::ItemView.new(@item_rep.item)
    end

    # @api private
    def to_recording_proxy
      @item_rep.to_recording_proxy
    end

    # @api private
    def raw_path(params = {})
      @item_rep.raw_path(params)
    end

    # @api private
    def compiled?
      @item_rep.compiled?
    end

    # @api private
    def compiled=(new_compiled)
      @item_rep.compiled = new_compiled
    end

    # @api private
    def forget_progress
      @item_rep.forget_progress
    end

    # @api private
    def assigns
      @item_rep.assigns
    end

    # @api private
    def assigns=(new_assigns)
      @item_rep.assigns = new_assigns
    end

    # @api private
    def type
      @item_rep.type
    end

    # @api private
    def reference
      @item_rep.reference
    end

    # @api private
    def snapshot(snapshot_name, params = {})
      @item_rep.snapshot(snapshot_name, params)
    end

    # @api private
    def filter(filter_name, filter_args = {})
      @item_rep.filter(filter_name, filter_args)
    end

    # @api private
    def layout(layout, filter_name, filter_args)
      @item_rep.layout(layout, filter_name, filter_args)
    end

    # @api private
    def proxy?
      @item_rep.proxy?
    end

    # @api private
    def binary?
      @item_rep.binary?
    end

    # @api private
    def has_snapshot?(snapshot_name)
      @item_rep.has_snapshot?(snapshot_name)
    end

    # @api private
    def content
      @item_rep.content
    end

    # @api private
    def temporary_filenames
      @item_rep.temporary_filenames
    end
  end
end
