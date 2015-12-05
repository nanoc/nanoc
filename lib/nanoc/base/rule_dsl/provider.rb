module Nanoc::Int
  class ActionProvider
    def rep_names_for(item)
      raise NotImplementedError
    end
  end
end

module Nanoc::Int
  class RuleDSLActionProvider < Nanoc::Int::ActionProvider
    def initialize(rules_collection)
      @rules_collection = rules_collection
    end

    def rep_names_for(item)
      matching_rules = @rules_collection.item_compilation_rules_for(item)
      raise Nanoc::Int::Errors::NoMatchingCompilationRuleFound.new(item) if matching_rules.empty?

      matching_rules.map(&:rep_name).uniq
    end
  end
end
