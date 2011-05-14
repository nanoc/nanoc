# encoding: utf-8

require 'forwardable'

module Nanoc3

  # TODO document
  #
  # @api private
  class ItemRepRecorderProxy

    extend Forwardable

    def_delegators :@item_rep, :item, :name, :binary, :binary?, :compiled_content, :has_snapshot?, :raw_path, :path, :assigns, :assigns=

    # TODO document
    attr_reader :rule_memory

    # @param [Nanoc3::ItemRep] item_rep The item representation that this
    #   proxy should behave like
    def initialize(item_rep)
      @item_rep = item_rep
      @rule_memory = []
    end

    # TODO document
    #
    # @see Nanoc3::ItemRepProxy#filter, Nanoc3::ItemRep#filter
    def filter(name, args={})
      @rule_memory << [ :filter, name, args ]
    end

    # TODO document
    #
    # @see Nanoc3::ItemRepProxy#layout, Nanoc3::ItemRep#layout
    def layout(layout_identifier)
      @rule_memory << [ :layout, layout_identifier ]
    end

    # TODO document
    #
    # @see Nanoc3::ItemRep#snapshot
    def snapshot(snapshot_name, params={})
      @rule_memory << [ :snapshot, snapshot_name, params ]
    end

    # TODO document
    def content
      {}
    end

    # TODO document
    def is_proxy?
      true
    end

  end

end
