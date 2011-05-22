# encoding: utf-8

module Nanoc3

  # Calculates rule memories for objects that can be run through a rule (item
  # representations and layouts).
  #
  # @api private
  class RuleMemoryCalculator

    extend Nanoc3::Memoization

    # @option params [Nanoc3::Site] site The site where this rule memory
    #   calculator belongs to
    def initialize(params={})
      super('tmp/rule_memory', 1)

      @site = params[:site] if params.has_key?(:site)
    end

    # @param [#reference] obj The object to calculate the rule memory for
    #
    # @return [Array] The caluclated rule memory for the given object
    def [](obj)
      result = case obj.type
        when :item_rep
          @site.compiler.rules_collection.new_rule_memory_for_rep(obj)
        when :layout
          @site.compiler.rules_collection.new_rule_memory_for_layout(obj)
        else
          raise RuntimeError,
            "Do not know how to calculate the rule memory for #{obj.inspect}"
      end

      result
    end
    memoize :[]

  end

end
