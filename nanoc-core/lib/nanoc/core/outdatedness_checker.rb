# frozen_string_literal: true

module Nanoc
  module Core
    # Responsible for determining whether an item or a layout is outdated.
    #
    # @api private
    class OutdatednessChecker
      class Basic
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

      include Nanoc::Core::ContractsSupport

      attr_reader :checksum_store
      attr_reader :checksums
      attr_reader :dependency_store
      attr_reader :action_sequence_store
      attr_reader :action_sequences
      attr_reader :site

      Reasons = Nanoc::Core::OutdatednessReasons

      C_OBJ = C::Or[Nanoc::Core::Item, Nanoc::Core::ItemRep, Nanoc::Core::Configuration, Nanoc::Core::Layout, Nanoc::Core::ItemCollection]
      C_ITEM_OR_REP = C::Or[Nanoc::Core::Item, Nanoc::Core::ItemRep]
      C_ACTION_SEQUENCES = C::HashOf[C_OBJ => Nanoc::Core::ActionSequence]

      contract C::KeywordArgs[site: Nanoc::Core::Site, checksum_store: Nanoc::Core::ChecksumStore, checksums: Nanoc::Core::ChecksumCollection, dependency_store: Nanoc::Core::DependencyStore, action_sequence_store: Nanoc::Core::ActionSequenceStore, action_sequences: C_ACTION_SEQUENCES, reps: Nanoc::Core::ItemRepRepo] => C::Any
      def initialize(site:, checksum_store:, checksums:, dependency_store:, action_sequence_store:, action_sequences:, reps:)
        @site = site
        @checksum_store = checksum_store
        @checksums = checksums
        @dependency_store = dependency_store
        @action_sequence_store = action_sequence_store
        @action_sequences = action_sequences
        @reps = reps

        @objects_outdated_due_to_dependencies = {}
      end

      def action_sequence_for(rep)
        @action_sequences.fetch(rep)
      end

      contract C_OBJ => C::Bool
      def outdated?(obj)
        outdatedness_reasons_for(obj).any?
      end

      contract C_OBJ => C::IterOf[Reasons::Generic]
      def outdatedness_reasons_for(obj)
        basic_reasons = basic_outdatedness_reasons_for(obj)
        if basic_reasons.any?
          basic_reasons
        elsif outdated_due_to_dependencies?(obj)
          [Reasons::DependenciesOutdated]
        else
          []
        end
      end

      contract C_OBJ => C::IterOf[Reasons::Generic]
      def basic_outdatedness_reasons_for(obj)
        # reasons = @basic_outdatedness_reasons.fetch(obj)
        reasons = basic.outdatedness_status_for(obj).reasons
        if reasons.any?
          reasons
        else
          []
        end
      end

      private

      contract C::None => Basic
      def basic
        @_basic ||= Basic.new(outdatedness_checker: self, reps: @reps)
      end

      contract C_OBJ, Hamster::Set => C::Bool
      def outdated_due_to_dependencies?(obj, processed = Hamster::Set.new)
        # Convert from rep to item if necessary
        obj = obj.item if obj.is_a?(Nanoc::Core::ItemRep)

        # Only items can have dependencies
        return false unless obj.is_a?(Nanoc::Core::Item)

        # Get from cache
        if @objects_outdated_due_to_dependencies.key?(obj)
          return @objects_outdated_due_to_dependencies[obj]
        end

        # Check processed
        # Don’t return true; the false will be or’ed into a true if there
        # really is a dependency that is causing outdatedness.
        return false if processed.include?(obj)

        # Calculate
        is_outdated = dependency_store.dependencies_causing_outdatedness_of(obj).any? do |dep|
          dependency_causes_outdatedness?(dep) ||
            (dep.props.compiled_content? &&
              outdated_due_to_dependencies?(dep.from, processed.merge([obj])))
        end

        # Cache
        @objects_outdated_due_to_dependencies[obj] = is_outdated

        # Done
        is_outdated
      end

      contract Nanoc::Core::Dependency => C::Bool
      def dependency_causes_outdatedness?(dependency)
        case dependency.from
        when nil
          true
        when Nanoc::Core::ItemCollection, Nanoc::Core::LayoutCollection
          all_objects = dependency.from

          raw_content_prop_causes_outdatedness?(all_objects, dependency.props.raw_content) ||
            attributes_prop_causes_outdatedness?(all_objects, dependency.props.attributes)
        else
          status = basic.outdatedness_status_for(dependency.from)

          active = status.props.active & dependency.props.active
          active.delete(:attributes) if attributes_unaffected?(status, dependency)

          !active.empty?
        end
      end

      def attributes_unaffected?(status, dependency)
        reason = status.reasons.find { |r| r.is_a?(Nanoc::Core::OutdatednessReasons::AttributesModified) }
        reason && dependency.props.attribute_keys.any? && (dependency.props.attribute_keys & reason.attributes).empty?
      end

      def raw_content_prop_causes_outdatedness?(objects, raw_content_prop)
        return false unless raw_content_prop

        matching_objects =
          case raw_content_prop
          when true
            # If the `raw_content` dependency prop is `true`, then this is a
            # dependency on all *objects* (items or layouts).
            objects
          when Enumerable
            # If the `raw_content` dependency prop is a collection, then this
            # is a dependency on specific objects, given by the patterns.
            patterns = raw_content_prop.map { |r| Nanoc::Core::Pattern.from(r) }
            patterns.flat_map { |pat| objects.select { |obj| pat.match?(obj.identifier) } }
          else
            raise(
              Nanoc::Core::Errors::InternalInconsistency,
              "Unexpected type of raw_content: #{raw_content_prop.inspect}",
            )
          end

        # For all objects matching the `raw_content` dependency prop:
        # If the object is outdated because it is newly added,
        # then this dependency causes outdatedness.
        #
        # Note that these objects might be modified but *not* newly added,
        # in which case this dependency will *not* cause outdatedness.
        # However, when the object is used later (e.g. attributes are
        # accessed), then another dependency will exist that will cause
        # outdatedness.
        matching_objects.any? do |obj|
          status = basic.outdatedness_status_for(obj)
          status.reasons.any? { |r| Nanoc::Core::OutdatednessReasons::DocumentAdded == r }
        end
      end

      def attributes_prop_causes_outdatedness?(objects, attributes_prop)
        return false unless attributes_prop

        unless attributes_prop.is_a?(Set)
          raise(
            Nanoc::Core::Errors::InternalInconsistency,
            'expected attributes_prop to be a Set',
          )
        end

        pairs = attributes_prop.select { |a| a.is_a?(Array) }.to_h

        unless pairs.any?
          raise(
            Nanoc::Core::Errors::InternalInconsistency,
            'expected attributes_prop not to be empty',
          )
        end

        dep_checksums = pairs.transform_values { |value| Nanoc::Core::Checksummer.calc(value) }

        objects.any? do |object|
          # Find old and new attribute checksums for the object
          old_object_checksums = checksum_store.attributes_checksum_for(object)
          next false unless old_object_checksums

          new_object_checksums = checksums.attributes_checksum_for(object)

          dep_checksums.any? do |key, dep_value|
            # Get old and new checksum for this particular attribute
            old_value = old_object_checksums[key]
            new_value = new_object_checksums[key]

            # If the old and new checksums are identical, then the attribute is
            # unchanged and can’t cause outdatedness.
            next false unless old_value != new_value

            # We already know that the old value and new value are different.
            # This attribute will cause outdatedness if either of those
            # checksums is identical to the one in the prop.
            old_value == dep_value || new_value == dep_value
          end
        end
      end
    end
  end
end
