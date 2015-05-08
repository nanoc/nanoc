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

    def name
      @item_rep.name
    end

    def compiled_content(params = {})
      @item_rep.compiled_content(params)
    end

    def path(params = {})
      @item_rep.path(params)
    end

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
