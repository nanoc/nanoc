# encoding: utf-8

module Nanoc

  # Represents a fake iem representation that does not actually perform any
  # actual filtering, layouting or snapshotting, but instead keeps track of
  # what would happen if a real item representation would have been used
  # instead. It therefore “records” the actions that happens upon it.
  #
  # The list of recorded actions is used during compilation to determine
  # whether an item representation needs to be recompiled: if the list of
  # actions is different from the list of actions from the previous
  # compilation run, the item needs to be recompiled; if it is the same, it
  # may not need to be recompiled.
  #
  # @api private
  class ItemRepRecorderProxy

    extend Forwardable

    def_delegators :@item_rep, :item, :name, :binary, :binary?, :compiled_content, :has_snapshot?, :raw_path, :path, :assigns, :assigns=

    # @example The compilation rule and the corresponding rule memory
    #
    #     # rule
    #     compile '/foo/' do
    #       filter :erb
    #       filter :myfilter, :arg1 => 'stuff'
    #       layout 'meh'
    #     end
    #
    #     # memory
    #     [
    #       [ :filter, :erb, {} ],
    #       [ :filter, :myfilter, { :arg1 => 'stuff' } ],
    #       [ :layout, 'meh' ]
    #     ]
    #
    # @return [Array] The list of recorded actions (“rule memory”)
    attr_reader :rule_memory

    # @param [Nanoc::ItemRep] item_rep The item representation that this
    #   proxy should behave like
    def initialize(item_rep)
      @item_rep = item_rep
      @rule_memory = []
    end

    # @return [void]
    #
    # @see Nanoc::ItemRepProxy#filter, Nanoc::ItemRep#filter
    def filter(name, args={})
      @rule_memory << [ :filter, name, args ]
    end

    # @return [void]
    #
    # @see Nanoc::ItemRepProxy#layout, Nanoc::ItemRep#layout
    def layout(layout_identifier, extra_filter_args=nil)
      if extra_filter_args
        @rule_memory << [ :layout, layout_identifier, extra_filter_args ]
      else
        @rule_memory << [ :layout, layout_identifier ]
      end
    end

    # @return [void]
    #
    # @see Nanoc::ItemRep#snapshot
    def snapshot(snapshot_name, params={})
      @rule_memory << [ :snapshot, snapshot_name, params ]

      # Count
      existing = Set.new
      names = @rule_memory.select { |r| r[0] == :snapshot }.map { |r| r[2] }
      names.each do |n|
        if existing.include?(n)
          raise Nanoc::Errors::CannotCreateMultipleSnapshotsWithSameName.new(@item_rep, snapshot_name)
        end
        existing << n
      end
    end

    # @return [{}]
    def content
      {}
    end

    # Returns true because this item is already a proxy, and therefore doesn’t
    # need to be wrapped anymore.
    #
    # @return [true]
    #
    # @see Nanoc::ItemRep#is_proxy?
    # @see Nanoc::ItemRepProxy#is_proxy?
    def is_proxy?
      true
    end

  end

end
