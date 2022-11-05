# frozen_string_literal: true

module Nanoc
  module Core
    module OutdatednessRules
      class RulesModified < Nanoc::Core::OutdatednessRule
        affects_props :compiled_content, :path

        def apply(obj, basic_outdatedness_checker)
          # Check rules of obj itself
          if rules_modified?(obj, basic_outdatedness_checker)
            return Nanoc::Core::OutdatednessReasons::RulesModified
          end

          # Check rules of layouts used by obj
          layouts = layouts_touched_by(obj, basic_outdatedness_checker)
          if layouts.any? { |layout| rules_modified?(layout, basic_outdatedness_checker) }
            return Nanoc::Core::OutdatednessReasons::RulesModified
          end

          nil
        end

        private

        def rules_modified?(obj, basic_outdatedness_checker)
          seq_old = basic_outdatedness_checker.action_sequence_store[obj]
          seq_new = basic_outdatedness_checker.action_sequence_for(obj).serialize

          !seq_old.eql?(seq_new)
        end

        def layouts_touched_by(obj, basic_outdatedness_checker)
          actions = basic_outdatedness_checker.action_sequence_store[obj]
          layout_actions = actions.select { |a| a.first == :layout }

          layouts = basic_outdatedness_checker.site.layouts

          layout_actions.map do |layout_action|
            layout_pattern = layout_action[1]
            layouts.object_with_identifier(layout_pattern) || layouts.object_matching_glob(layout_pattern)
          end.compact
        end
      end
    end
  end
end
