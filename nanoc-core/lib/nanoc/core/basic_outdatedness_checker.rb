# frozen_string_literal: true

module Nanoc
  module Core
    class BasicOutdatednessChecker
      include Nanoc::Core::ContractsSupport

      attr_reader :site
      attr_reader :checksum_store
      attr_reader :checksums
      attr_reader :dependency_store
      attr_reader :action_sequence_store
      attr_reader :action_sequences

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

      C_OBJ = C::Or[
        Nanoc::Core::Item,
        Nanoc::Core::ItemRep,
        Nanoc::Core::Configuration,
        Nanoc::Core::Layout,
        Nanoc::Core::ItemCollection,
      ]

      C_OBJ_MAYBE_REP = C::Or[
        Nanoc::Core::Item,
        Nanoc::Core::ItemRep,
        Nanoc::Core::Configuration,
        Nanoc::Core::Layout,
        Nanoc::Core::ItemCollection,
        Nanoc::Core::LayoutCollection,
      ]

      C_ACTION_SEQUENCES = C::HashOf[C_OBJ => Nanoc::Core::ActionSequence]

      contract C::KeywordArgs[
        site: Nanoc::Core::Site,
        checksum_store: Nanoc::Core::ChecksumStore,
        checksums: Nanoc::Core::ChecksumCollection,
        dependency_store: Nanoc::Core::DependencyStore,
        action_sequence_store: Nanoc::Core::ActionSequenceStore,
        action_sequences: C_ACTION_SEQUENCES,
        reps: Nanoc::Core::ItemRepRepo,
      ] => C::Any
      def initialize(site:, checksum_store:, checksums:, dependency_store:, action_sequence_store:, action_sequences:, reps:)
        @reps = reps
        @site = site
        @checksum_store = checksum_store
        @checksums = checksums
        @dependency_store = dependency_store
        @action_sequence_store = action_sequence_store
        @action_sequences = action_sequences

        # Memoize
        @_outdatedness_status_for = {}
      end

      contract C_OBJ_MAYBE_REP => C::Maybe[Nanoc::Core::OutdatednessStatus]
      def outdatedness_status_for(obj)
        # TODO: remove memoization (no longer needed)
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

      def action_sequence_for(rep)
        @action_sequences.fetch(rep)
      end

      private

      contract C::ArrayOf[Class], C_OBJ_MAYBE_REP, Nanoc::Core::OutdatednessStatus => C::Maybe[Nanoc::Core::OutdatednessStatus]
      def apply_rules(rules, obj, status = Nanoc::Core::OutdatednessStatus.new)
        rules.inject(status) do |acc, rule|
          if acc.useful_to_apply?(rule)
            reason = rule.instance.call(obj, self)
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
        objs.inject(Nanoc::Core::OutdatednessStatus.new) do |acc, elem|
          apply_rules(rules, elem, acc)
        end
      end
    end
  end
end
