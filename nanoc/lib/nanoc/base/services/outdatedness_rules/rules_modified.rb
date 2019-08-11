# frozen_string_literal: true

module Nanoc
  module Int
    module OutdatednessRules
      class RulesModified < Nanoc::Int::OutdatednessRule
        affects_props :compiled_content, :path

        def apply(obj, outdatedness_checker)
          # Check rules of obj itself
          if rules_modified?(obj, outdatedness_checker)
            return Nanoc::Core::OutdatednessReasons::RulesModified
          end

          # Check rules of layouts used by obj
          layouts = layouts_touched_by(obj, outdatedness_checker)
          if layouts.any? { |layout| rules_modified?(layout, outdatedness_checker) }
            return Nanoc::Core::OutdatednessReasons::RulesModified
          end

          nil
        end

        private

        def rules_modified?(obj, outdatedness_checker)
          seq_old = outdatedness_checker.action_sequence_store[obj]
          seq_new = outdatedness_checker.action_sequence_for(obj).serialize

          !seq_old.eql?(seq_new)
        end

        def layouts_touched_by(obj, outdatedness_checker)
          actions = outdatedness_checker.action_sequence_store[obj]
          layout_actions = actions.select { |a| a.first == :layout }

          layout_actions.map do |layout_action|
            layout_pattern = layout_action[1]
            outdatedness_checker.site.layouts[layout_pattern]
          end.compact
        end
      end
    end
  end
end
