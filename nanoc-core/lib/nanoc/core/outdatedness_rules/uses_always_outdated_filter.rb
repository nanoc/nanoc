# frozen_string_literal: true

module Nanoc
  module Core
    module OutdatednessRules
      class UsesAlwaysOutdatedFilter < Nanoc::Core::OutdatednessRule
        affects_props :raw_content, :attributes, :path

        def apply(obj, outdatedness_checker)
          seq = outdatedness_checker.action_sequence_for(obj)
          if any_always_outdated?(seq)
            Nanoc::Core::OutdatednessReasons::UsesAlwaysOutdatedFilter
          end
        end

        def any_always_outdated?(seq)
          seq
            .select { |a| a.is_a?(Nanoc::Core::ProcessingActions::Filter) }
            .map { |a| Nanoc::Core::Filter.named(a.filter_name) }
            .compact
            .any?(&:always_outdated?)
        end
      end
    end
  end
end
