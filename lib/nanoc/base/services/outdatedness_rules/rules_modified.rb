module Nanoc::Int::OutdatednessRules
  class RulesModified < Nanoc::Int::OutdatednessRule
    affects_props :compiled_content, :path

    def apply(obj, outdatedness_checker)
      mem_old = outdatedness_checker.rule_memory_store[obj]
      mem_new = outdatedness_checker.action_provider.memory_for(obj).serialize
      unless mem_old.eql?(mem_new)
        Nanoc::Int::OutdatednessReasons::RulesModified
      end
    end
  end
end
