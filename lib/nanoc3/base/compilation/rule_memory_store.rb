# encoding: utf-8

module Nanoc3

  # TODO document
  #
  # @api private
  class RuleMemoryStore < ::Nanoc3::Store

    # @option params [Nanoc3::Site] site The site where this checksum store
    #   belongs to
    def initialize(params={})
      super('tmp/rule_memory', 1)

      @site = params[:site] if params.has_key?(:site)

      @rule_memories = {}
    end

    # TODO document
    def [](obj)
      @rule_memories[obj.reference]
    end

    # TODO document
    def []=(obj, rule_memory)
      @rule_memories[obj.reference] = rule_memory
    end

    # @see Nanoc3::Store#store
    def store
      calculate_all_rule_memories
      super
    end

  protected

    def new_rule_memory_for_rep(rep)
      @site.compiler.new_rule_memory_for_rep(rep)
    end

    def new_rule_memory_for_layout(layout)
      @site.compiler.new_rule_memory_for_layout(layout)
    end

    def calculate_all_rule_memories
      reps    = @site.items.map { |i| i.reps }.flatten
      layouts = @site.layouts

      reps.each    { |r| new_rule_memory_for_rep(r) }
      layouts.each { |l| new_rule_memory_for_layout(l) }
    end

    def data
      @rule_memories
    end

    def data=(new_data)
      @rule_memories = new_data
    end

  end

end
