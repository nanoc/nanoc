module Nanoc::Int
  # Responsible for determining whether an item or a layout is outdated.
  #
  # @api private
  class OutdatednessChecker
    class Basic
      extend Nanoc::Int::Memoization

      include Nanoc::Int::ContractsSupport

      Rules = Nanoc::Int::OutdatednessRules

      RULES_FOR_ITEM_REP =
        [
          Rules::RulesModified,
          Rules::PathsModified,
          Rules::ContentModified,
          Rules::AttributesModified,
          Rules::NotWritten,
          Rules::CodeSnippetsModified,
          Rules::ConfigurationModified,
          Rules::UsesAlwaysOutdatedFilter,
        ].freeze

      RULES_FOR_LAYOUT =
        [
          Rules::RulesModified,
          Rules::ContentModified,
          Rules::AttributesModified,
          Rules::UsesAlwaysOutdatedFilter,
        ].freeze

      contract C::KeywordArgs[outdatedness_checker: OutdatednessChecker, reps: Nanoc::Int::ItemRepRepo] => C::Any
      def initialize(outdatedness_checker:, reps:)
        @outdatedness_checker = outdatedness_checker
        @reps = reps
      end

      contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::Maybe[OutdatednessStatus]
      memoized def outdatedness_status_for(obj)
        case obj
        when Nanoc::Int::ItemRep
          apply_rules(RULES_FOR_ITEM_REP, obj)
        when Nanoc::Int::Item
          apply_rules_multi(RULES_FOR_ITEM_REP, @reps[obj])
        when Nanoc::Int::Layout
          apply_rules(RULES_FOR_LAYOUT, obj)
        else
          raise Nanoc::Int::Errors::InternalInconsistency, "do not know how to check outdatedness of #{obj.inspect}"
        end
      end

      private

      contract C::ArrayOf[Class], C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout], OutdatednessStatus => C::Maybe[OutdatednessStatus]
      def apply_rules(rules, obj, status = OutdatednessStatus.new)
        rules.inject(status) do |acc, rule|
          if !acc.useful_to_apply?(rule)
            acc
          else
            reason = rule.instance.call(obj, @outdatedness_checker)
            if reason
              acc.update(reason)
            else
              acc
            end
          end
        end
      end

      contract C::ArrayOf[Class], C::ArrayOf[C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout]] => C::Maybe[OutdatednessStatus]
      def apply_rules_multi(rules, objs)
        objs.inject(OutdatednessStatus.new) { |acc, elem| apply_rules(rules, elem, acc) }
      end
    end

    extend Nanoc::Int::Memoization

    include Nanoc::Int::ContractsSupport

    attr_reader :checksum_store
    attr_reader :dependency_store
    attr_reader :action_sequence_store
    attr_reader :action_sequences
    attr_reader :site

    Reasons = Nanoc::Int::OutdatednessReasons

    C_OBJ = C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout]
    C_ACTION_SEQUENCES = C::HashOf[C_OBJ => Nanoc::Int::ActionSequence]

    contract C::KeywordArgs[site: Nanoc::Int::Site, checksum_store: Nanoc::Int::ChecksumStore, dependency_store: Nanoc::Int::DependencyStore, action_sequence_store: Nanoc::Int::ActionSequenceStore, action_sequences: C_ACTION_SEQUENCES, reps: Nanoc::Int::ItemRepRepo] => C::Any
    def initialize(site:, checksum_store:, dependency_store:, action_sequence_store:, action_sequences:, reps:)
      @site = site
      @checksum_store = checksum_store
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

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::IterOf[Reasons::Generic]
    def outdatedness_reasons_for(obj)
      reasons = basic.outdatedness_status_for(obj).reasons
      if reasons.any?
        reasons
      elsif outdated_due_to_dependencies?(obj)
        [Reasons::DependenciesOutdated]
      else
        []
      end
    end

    private

    contract C::None => Basic
    def basic
      @_basic ||= Basic.new(outdatedness_checker: self, reps: @reps)
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout], Hamster::Set => C::Bool
    def outdated_due_to_dependencies?(obj, processed = Hamster::Set.new)
      # Convert from rep to item if necessary
      obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)

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

    contract Nanoc::Int::Dependency => C::Bool
    def dependency_causes_outdatedness?(dependency)
      return true if dependency.from.nil?

      status = basic.outdatedness_status_for(dependency.from)

      active = status.props.active & dependency.props.active
      if attributes_unaffected?(status, dependency)
        active.delete(:attributes)
      end

      active.any?
    end

    def attributes_unaffected?(status, dependency)
      attr_reason = status.reasons.find do |r|
        r.is_a?(Nanoc::Int::OutdatednessReasons::AttributesModified)
      end

      attr_reason && dependency.props.attributes.is_a?(Enumerable) && (dependency.props.attributes & attr_reason.attributes).empty?
    end
  end
end
