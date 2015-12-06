module Nanoc::RuleDSL
  class ActionProvider < Nanoc::Int::ActionProvider
    # TODO: Convert this into a plugin

    def initialize(rules_collection, rule_memory_calculator)
      @rules_collection = rules_collection
      @rule_memory_calculator = rule_memory_calculator
    end

    def rep_names_for(item)
      matching_rules = @rules_collection.item_compilation_rules_for(item)
      raise Nanoc::Int::Errors::NoMatchingCompilationRuleFound.new(item) if matching_rules.empty?

      matching_rules.map(&:rep_name).uniq
    end

    def memory_for(rep)
      @rule_memory_calculator[rep]
    end

    def snapshots_defs_for(rep)
      @rule_memory_calculator.snapshots_defs_for(rep)
    end
  end
end
