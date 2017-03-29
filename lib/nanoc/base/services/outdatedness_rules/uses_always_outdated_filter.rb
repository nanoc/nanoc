module Nanoc::Int::OutdatednessRules
  class UsesAlwaysOutdatedFilter < Nanoc::Int::OutdatednessRule
    affects_props :raw_content, :attributes, :path

    def apply(obj, outdatedness_checker)
      mem = outdatedness_checker.memory_for(obj)
      if any_always_outdated?(mem)
        Nanoc::Int::OutdatednessReasons::UsesAlwaysOutdatedFilter
      end
    end

    def any_always_outdated?(mem)
      mem
        .select { |a| a.is_a?(Nanoc::Int::ProcessingActions::Filter) }
        .map { |a| Nanoc::Filter.named(a.filter_name) }
        .compact
        .any?(&:always_outdated?)
    end
  end
end
