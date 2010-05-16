# encoding: utf-8

require 'forwardable'

module Nanoc3

  # TODO document
  class ItemRepProxy

    extend Forwardable

    def_delegators :@item_rep, :item, :name, :binary, :binary?, :compiled_content, :has_snapshot?, :raw_path, :path
    def_delegator  :@item_rep, :snapshot

    # TODO document
    def initialize(item_rep, compiler)
      @item_rep = item_rep
      @compiler = compiler
    end

    # TODO document
    def filter(name, args={})
      set_assigns
      @item_rep.filter(name, args)
    end

    # TODO document
    def layout(layout_identifier)
      set_assigns
      @item_rep.layout(layout_identifier)
    end

  private

    def set_assigns
      @item_rep.assigns = @compiler.assigns_for(@item_rep)
    end

  end

end
