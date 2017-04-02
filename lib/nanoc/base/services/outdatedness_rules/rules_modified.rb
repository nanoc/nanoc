module Nanoc::Int::OutdatednessRules
  class RulesModified < Nanoc::Int::OutdatednessRule
    affects_props :compiled_content, :path

    def apply(obj, outdatedness_checker)
      seq_old = outdatedness_checker.action_sequence_store[obj]
      seq_new = outdatedness_checker.action_sequence_for(obj).serialize
      unless seq_old.eql?(seq_new)
        Nanoc::Int::OutdatednessReasons::RulesModified
      end
    end
  end
end
