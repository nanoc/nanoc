# encoding: utf-8

module Nanoc3

  # Stores rule memories for objects that can be run through a rule (item
  # representations and layouts).
  #
  # @api private
  class RuleMemoryStore < ::Nanoc3::Store

    # @option params [Nanoc3::Site] site The site where this rule memory store
    #   belongs to
    def initialize(params={})
      super('tmp/rule_memory', 1)

      @site = params[:site] if params.has_key?(:site)

      @old_rule_memories = {}
      @new_rule_memories = {}
    end

    # @param [#reference] obj The object to get the rule memory for
    #
    # @return [Array] The old rule memory for the given object
    def old_rule_memory_for(obj)
      @old_rule_memories[obj.reference]
    end

    # @param [Nanoc3::ItemRep] rep The item rep to get the rule memory for
    #
    # @return [Array] The new rule memory for the given item representation
    def new_rule_memory_for_rep(rep)
      @new_rule_memories[rep.reference] ||=
        @site.compiler.new_rule_memory_for_rep(rep)
    end

    # @param [Nanoc3::Layout] layout The layout to get the rule memory for
    #
    # @return [Array] The new rule memory for the given layout
    def new_rule_memory_for_layout(layout)
      @new_rule_memories[layout.reference] ||=
        @site.compiler.new_rule_memory_for_layout(layout)
    end

    # @see Nanoc3::Store#store
    def store
      calculate_all_rule_memories
      super
    end

  protected

    def calculate_all_rule_memories
      reps    = @site.items.map { |i| i.reps }.flatten
      layouts = @site.layouts

      reps.each    { |r| new_rule_memory_for_rep(r) }
      layouts.each { |l| new_rule_memory_for_layout(l) }
    end

    def data
      @new_rule_memories
    end

    def data=(new_data)
      @old_rule_memories = new_data
    end

  end

end
