module Nanoc::Int::OutdatednessRules
  class PathsModified < Nanoc::Int::OutdatednessRule
    affects_props :path

    def apply(obj, outdatedness_checker)
      # FIXME: Prefer to not work on serialised version

      mem_old = outdatedness_checker.action_sequence_store[obj]
      mem_new = outdatedness_checker.action_sequence_for(obj).serialize
      return true if mem_old.nil?

      paths_old = mem_old.select { |pa| pa[0] == :snapshot }
      paths_new = mem_new.select { |pa| pa[0] == :snapshot }

      if paths_old != paths_new
        Nanoc::Int::OutdatednessReasons::PathsModified
      end
    end
  end
end
