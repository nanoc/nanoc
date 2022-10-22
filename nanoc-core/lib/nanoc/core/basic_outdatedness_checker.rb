# frozen_string_literal: true

module Nanoc
  module Core
    class BasicOutdatednessChecker
      include Nanoc::Core::ContractsSupport

      Rules = Nanoc::Core::OutdatednessRules

      RULES_FOR_ITEM_REP =
        [
          Rules::ItemAdded,
          Rules::RulesModified,
          Rules::ContentModified,
          Rules::AttributesModified,
          Rules::NotWritten,
          Rules::CodeSnippetsModified,
          Rules::UsesAlwaysOutdatedFilter,
        ].freeze

      RULES_FOR_LAYOUT =
        [
          Rules::LayoutAdded,
          Rules::RulesModified,
          Rules::ContentModified,
          Rules::AttributesModified,
          Rules::UsesAlwaysOutdatedFilter,
        ].freeze

      RULES_FOR_CONFIG =
        [
          Rules::AttributesModified,
        ].freeze

      C_OBJ_MAYBE_REP = C::Or[Nanoc::Core::Item, Nanoc::Core::ItemRep, Nanoc::Core::Configuration, Nanoc::Core::Layout, Nanoc::Core::ItemCollection, Nanoc::Core::LayoutCollection]

      contract C::KeywordArgs[outdatedness_checker: OutdatednessChecker, reps: Nanoc::Core::ItemRepRepo] => C::Any
      def initialize(outdatedness_checker:, reps:)
        @outdatedness_checker = outdatedness_checker
        @reps = reps

        # Memoize
        @_outdatedness_status_for = {}
      end

      contract C_OBJ_MAYBE_REP => C::Maybe[Nanoc::Core::OutdatednessStatus]
      def outdatedness_status_for(obj)
        @_outdatedness_status_for[obj] ||=
          case obj
          when Nanoc::Core::ItemRep
            apply_rules(RULES_FOR_ITEM_REP, obj)
          when Nanoc::Core::Item
            apply_rules_multi(RULES_FOR_ITEM_REP, @reps[obj])
          when Nanoc::Core::Layout
            apply_rules(RULES_FOR_LAYOUT, obj)
          when Nanoc::Core::Configuration
            apply_rules(RULES_FOR_CONFIG, obj)
          when Nanoc::Core::ItemCollection, Nanoc::Core::LayoutCollection
            # Collections are never outdated. Objects inside them might be,
            # however.
            apply_rules([], obj)
          else
            raise Nanoc::Core::Errors::InternalInconsistency, "do not know how to check outdatedness of #{obj.inspect}"
          end
      end

      private

      contract C::ArrayOf[Class], C_OBJ_MAYBE_REP, Nanoc::Core::OutdatednessStatus => C::Maybe[Nanoc::Core::OutdatednessStatus]
      def apply_rules(rules, obj, status = Nanoc::Core::OutdatednessStatus.new)
        rules.inject(status) do |acc, rule|
          if acc.useful_to_apply?(rule)
            reason = rule.instance.call(obj, @outdatedness_checker)
            if reason
              acc.update(reason)
            else
              acc
            end
          else
            acc
          end
        end
      end

      contract C::ArrayOf[Class], C::ArrayOf[C_OBJ_MAYBE_REP] => C::Maybe[Nanoc::Core::OutdatednessStatus]
      def apply_rules_multi(rules, objs)
        objs.inject(Nanoc::Core::OutdatednessStatus.new) { |acc, elem| apply_rules(rules, elem, acc) }
      end
    end
  end
end
