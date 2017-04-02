module Nanoc::Int::OutdatednessRules
  class UsesAlwaysOutdatedFilter < Nanoc::Int::OutdatednessRule
    affects_props :raw_content, :attributes, :path

    def apply(obj, outdatedness_checker)
      seq = outdatedness_checker.action_sequence_for(obj)
      if any_always_outdated?(seq)
        Nanoc::Int::OutdatednessReasons::UsesAlwaysOutdatedFilter
      end
    end

    def any_always_outdated?(seq)
      seq
        .select { |a| a.is_a?(Nanoc::Int::ProcessingActions::Filter) }
        .map { |a| Nanoc::Filter.named(a.filter_name) }
        .compact
        .any?(&:always_outdated?)
    end
  end
end
