# frozen_string_literal: true

module Nanoc
  module Core
    # Responsible for determining whether an item or a layout is outdated.
    #
    # @api private
    class OutdatednessChecker
      include Nanoc::Core::ContractsSupport

      attr_reader :checksum_store
      attr_reader :checksums
      attr_reader :dependency_store
      attr_reader :action_sequence_store
      attr_reader :action_sequences
      attr_reader :site

      Reasons = Nanoc::Core::OutdatednessReasons

      C_OBJ = C::Or[
        Nanoc::Core::Item,
        Nanoc::Core::ItemRep,
        Nanoc::Core::Configuration,
        Nanoc::Core::Layout,
        Nanoc::Core::ItemCollection,
      ]
      C_ITEM_OR_REP = C::Or[Nanoc::Core::Item, Nanoc::Core::ItemRep]
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
      def initialize(
        site:, checksum_store:, checksums:, dependency_store:,
        action_sequence_store:, action_sequences:, reps:
      )
        @site = site
        @checksum_store = checksum_store
        @checksums = checksums
        @dependency_store = dependency_store
        @action_sequence_store = action_sequence_store
        @action_sequences = action_sequences
        @reps = reps

        @objects_outdated_due_to_dependencies = {}
        @ran = false
      end

      contract C_OBJ => C::IterOf[Reasons::Generic]
      def outdatedness_reasons_for(obj)
        precalculate

        basic_reasons = @basic_outdatedness_statuses.fetch(obj).reasons
        unless basic_reasons.empty?
          return basic_reasons
        end

        obj = obj.item if obj.is_a?(Nanoc::Core::ItemRep)
        if @objs_outdated_due_to_dependencies.include?(obj)
          return [Reasons::DependenciesOutdated]
        end

        []
      end

      private

      def precalculate
        return if @precalculated

        @basic_outdatedness_statuses, basic_outdated_objs =
          calc_basic_outdatedness_statuses

        @objs_outdated_due_to_dependencies =
          propagate_outdatedness(
            @basic_outdatedness_statuses,
            basic_outdated_objs,
          )

        @precalculated = true
      end

      def propagate_outdatedness(
        basic_outdatedness_statuses,
        basic_outdated_objs
      )
        objs_outdated_due_to_dependencies = Set.new

        seen = Set.new
        pending = [nil, @site.items, @site.layouts] + basic_outdated_objs.to_a
        until pending.empty?
          obj = pending.shift
          obj = obj.item if obj.is_a?(Nanoc::Core::ItemRep)
          next if seen.include?(obj)

          seen << obj

          deps = dependency_store.dependencies_outdated_because_of(obj)
          deps.each do |dep|
            # NOTE: dep.from == obj

            status = basic_outdatedness_statuses[dep.to]
            next if status && status.reasons.size.positive?
            next if objs_outdated_due_to_dependencies.include?(dep.to)

            case dep.from # from = what causes outdatedness

            when nil
              # Dependency from a removed object
              objs_outdated_due_to_dependencies << dep.to
              pending << dep.to

            when Nanoc::Core::ItemCollection,
              Nanoc::Core::LayoutCollection
              coll = dep.from # or simply `obj`
              props = dep.props

              if raw_content_prop_causes_outdatedness?(
                coll, props.raw_content, basic_outdatedness_statuses
              ) || attributes_prop_causes_outdatedness?(
                coll, props.attributes
              )
                objs_outdated_due_to_dependencies << dep.to
                pending << dep.to
              end

            when Nanoc::Core::Item,
              Nanoc::Core::Layout,
              Nanoc::Core::Configuration
              status = basic_outdatedness_statuses[dep.from]

              active = status.props.active & dep.props.active
              if attributes_unaffected?(status, dep)
                active &= ~DependencyProps::BIT_PATTERN_ATTRIBUTES
              end

              if active != 0x00 || (
                dep.props.compiled_content? &&
                objs_outdated_due_to_dependencies.include?(dep.from)
              )
                objs_outdated_due_to_dependencies << dep.to
                pending << dep.to
              end

            else
              raise Nanoc::Core::Errors::InternalInconsistency,
                    "unexpected object type: #{dep.from.inspect}"
            end
          end
        end

        objs_outdated_due_to_dependencies
      end

      def calc_basic_outdatedness_statuses
        basic_outdatedness_statuses = {}
        basic_outdated_objs = Set.new

        collections = [
          [@site.config, @site.layouts, @site.items],
          @site.layouts,
          @site.items,
          @reps,
        ]

        collections.each do |collection|
          collection.each do |obj|
            status = basic.outdatedness_status_for(obj)

            basic_outdatedness_statuses[obj] = status

            unless status.reasons.empty?
              basic_outdated_objs << obj
            end
          end
        end

        [basic_outdatedness_statuses, basic_outdated_objs.freeze]
      end

      contract C::None => BasicOutdatednessChecker
      def basic
        @_basic ||= BasicOutdatednessChecker.new(
          site: @site,
          checksum_store: @checksum_store,
          checksums: @checksums,
          dependency_store: @dependency_store,
          action_sequence_store: @action_sequence_store,
          action_sequences: @action_sequences,
          reps: @reps,
        )
      end

      def attributes_unaffected?(status, dependency)
        reason = status.reasons.find do |r|
          r.is_a?(Nanoc::Core::OutdatednessReasons::AttributesModified)
        end

        reason &&
          !dependency.props.attribute_keys.empty? &&
          !dependency.props.attribute_keys.intersect?(reason.attributes)
      end

      def raw_content_prop_causes_outdatedness?(
        collection, raw_content_prop, basic_outdatedness_statuses
      )
        return false unless raw_content_prop

        document_added_reason =
          basic_outdatedness_statuses
          .fetch(collection)
          .reasons
          .grep(Nanoc::Core::OutdatednessReasons::DocumentAdded)
          .first
        return false unless document_added_reason

        case raw_content_prop
        when true
          true

        when Enumerable
          patterns = raw_content_prop
          identifiers = document_added_reason.identifiers

          patterns.any? do |pat|
            coerced_pattern = Nanoc::Core::Pattern.from(pat)

            identifiers.any? do |identifier|
              coerced_pattern.match?(identifier)
            end
          end

        else
          raise(
            Nanoc::Core::Errors::InternalInconsistency,
            "Unexpected type of raw_content: #{raw_content_prop.inspect}",
          )

        end
      end

      def attributes_prop_causes_outdatedness?(objects, attributes_prop)
        return false unless attributes_prop

        unless attributes_prop.is_a?(Set) || attributes_prop.is_a?(Array)
          raise(
            Nanoc::Core::Errors::InternalInconsistency,
            'expected attributes_prop to be a Set',
          )
        end

        pairs = attributes_prop.grep(Array).to_h

        if pairs.empty?
          raise(
            Nanoc::Core::Errors::InternalInconsistency,
            'expected attributes_prop not to be empty',
          )
        end

        dep_checksums = pairs.transform_values do |value|
          Nanoc::Core::Checksummer.calc(value)
        end

        objects.any? do |object|
          # Find old and new attribute checksums for the object
          old_object_checksums = checksum_store.attributes_checksum_for(object)
          new_object_checksums = checksums.attributes_checksum_for(object)

          dep_checksums.any? do |key, dep_value|
            if old_object_checksums
              # Get old and new checksum for this particular attribute
              old_value = old_object_checksums[key]
              new_value = new_object_checksums[key]

              # If the old and new checksums are identical, then the attribute
              # is unchanged and can’t cause outdatedness.
              next false unless old_value != new_value

              # We already know that the old value and new value are different.
              # This attribute will cause outdatedness if either of those
              # checksums is identical to the one in the prop.
              old_value == dep_value || new_value == dep_value
            else
              # We don’t have the previous checksums, which means this item is
              # newly added. In this case, we can compare the value in the
              # dependency with the new checksum.

              new_value = new_object_checksums[key]
              new_value == dep_value
            end
          end
        end
      end
    end
  end
end
