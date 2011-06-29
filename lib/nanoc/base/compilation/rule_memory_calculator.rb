# encoding: utf-8

module Nanoc

  # Calculates rule memories for objects that can be run through a rule (item
  # representations and layouts).
  #
  # @api private
  class RuleMemoryCalculator

    extend Nanoc::Memoization

    # @option params [Nanoc::RulesCollection] rules_collection The rules
    #   collection
    def initialize(params={})
      @rules_collection = params[:rules_collection] or
        raise ArgumentError, "Required :rules_collection option is missing"
    end

    # @param [#reference] obj The object to calculate the rule memory for
    #
    # @return [Array] The caluclated rule memory for the given object
    def [](obj)
      result = case obj.type
        when :item_rep
          @rules_collection.new_rule_memory_for_rep(obj)
        when :layout
          @rules_collection.new_rule_memory_for_layout(obj)
        else
          raise RuntimeError,
            "Do not know how to calculate the rule memory for #{obj.inspect}"
      end

      result
    end
    memoize :[]

  end

end
