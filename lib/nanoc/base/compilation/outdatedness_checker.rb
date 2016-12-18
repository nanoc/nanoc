module Nanoc::Int
  # Responsible for determining whether an item or a layout is outdated.
  #
  # @api private
  class OutdatednessChecker
    extend Nanoc::Int::Memoization

    include Nanoc::Int::ContractsSupport

    attr_reader :checksum_store
    attr_reader :dependency_store
    attr_reader :rule_memory_store
    attr_reader :site

    Reasons = Nanoc::Int::OutdatednessReasons
    Rules = Nanoc::Int::OutdatednessRules

    # @param [Nanoc::Int::Site] site
    # @param [Nanoc::Int::ChecksumStore] checksum_store
    # @param [Nanoc::Int::DependencyStore] dependency_store
    # @param [Nanoc::Int::RuleMemoryStore] rule_memory_store
    # @param [Nanoc::Int::ActionProvider] action_provider
    # @param [Nanoc::Int::ItemRepRepo] reps
    def initialize(site:, checksum_store:, dependency_store:, rule_memory_store:, action_provider:, reps:)
      @site = site
      @checksum_store = checksum_store
      @dependency_store = dependency_store
      @rule_memory_store = rule_memory_store
      @action_provider = action_provider
      @reps = reps

      @basic_outdatedness_reasons = {}
      @outdatedness_reasons = {}
      @objects_outdated_due_to_dependencies = {}
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::Bool
    # Checks whether the given object is outdated and therefore needs to be
    # recompiled.
    #
    # @param [Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The object
    #   whose outdatedness should be checked.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def outdated?(obj)
      !outdatedness_reason_for(obj).nil?
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::Maybe[Reasons::Generic]
    # Calculates the reason why the given object is outdated.
    #
    # @param [Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The object
    #   whose outdatedness reason should be calculated.
    #
    # @return [Reasons::Generic, nil] The reason why the
    #   given object is outdated, or nil if the object is not outdated.
    def outdatedness_reason_for(obj)
      reason = basic_outdatedness_reason_for(obj)
      if reason.nil? && outdated_due_to_dependencies?(obj)
        reason = Reasons::DependenciesOutdated
      end
      reason
    end
    memoize :outdatedness_reason_for

    private

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::Bool
    # Checks whether the given object is outdated and therefore needs to be
    # recompiled. This method does not take dependencies into account; use
    # {#outdated?} if you want to include dependencies in the outdatedness
    # check.
    #
    # @param [Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The object
    #   whose outdatedness should be checked.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def basic_outdated?(obj)
      !basic_outdatedness_reason_for(obj).nil?
    end

    class Status
      def initialize(reasons: [], raw_content: false, attributes: false, compiled_content: false, path: false)
        @reasons = reasons
        @raw_content = raw_content
        @attributes = attributes
        @compiled_content = compiled_content
        @path = path
      end

      def reasons
        @reasons
      end

      def raw_content?
        @raw_content
      end

      def attributes?
        @attributes
      end

      def compiled_content?
        @compiled_content
      end

      def path?
        @path
      end

      def active_props
        Set.new.tap do |pr|
          pr << :raw_content if raw_content?
          pr << :attributes if attributes?
          pr << :compiled_content if compiled_content?
          pr << :path if path?
        end
      end

      def useful_to_apply?(rule)
        (rule.instance.reason.active_props - active_props).any?
      end

      def update(reason)
        self.class.new(
          reasons: reasons + [reason],
          raw_content: @raw_content || reason.raw_content?,
          attributes: @attributes || reason.attributes?,
          compiled_content: @compiled_content || reason.compiled_content?,
          path: @path || reason.path?,
        )
      end
    end

    RULES_FOR_ITEM_REP =
      [
        Rules::RulesModified,
        Rules::NotEnoughData,
        Rules::ContentModified,
        Rules::AttributesModified,
        Rules::NotWritten,
        Rules::CodeSnippetsModified,
        Rules::ConfigurationModified,
      ].freeze

    RULES_FOR_LAYOUT =
      [
        Rules::RulesModified,
        Rules::NotEnoughData,
        Rules::ContentModified,
        Rules::AttributesModified,
      ].freeze

    def apply_rules(rules, obj, status = Status.new)
      rules.inject(status) do |acc, rule|
        if !acc.useful_to_apply?(rule)
          acc
        elsif rule.instance.apply(obj, self)
          acc.update(rule.instance.reason)
        else
          acc
        end
      end
    end

    def apply_rules_multi(rules, objs)
      objs.inject(Status.new) { |acc, elem| apply_rules(rules, elem, acc) }
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::Maybe[Reasons::Generic]
    # Calculates the reason why the given object is outdated. This method does
    # not take dependencies into account; use {#outdatedness_reason_for?} if
    # you want to include dependencies in the outdatedness check.
    #
    # @param [Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The object
    #   whose outdatedness reason should be calculated.
    #
    # @return [Reasons::Generic, nil] The reason why the
    #   given object is outdated, or nil if the object is not outdated.
    def basic_outdatedness_reason_for(obj)
      # FIXME: Stop using this; it is no longer accurate, as there can be >1 reasons
      basic_outdatedness_status_for(obj).reasons.first
    end

    def basic_outdatedness_status_for(obj)
      case obj
      when Nanoc::Int::ItemRep
        apply_rules(RULES_FOR_ITEM_REP, obj)
      when Nanoc::Int::Item
        apply_rules_multi(RULES_FOR_ITEM_REP, @reps[obj])
      when Nanoc::Int::Layout
        apply_rules(RULES_FOR_LAYOUT, obj)
      else
        raise "do not know how to check outdatedness of #{obj.inspect}"
      end
    end
    memoize :basic_outdatedness_status_for

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout], Hamster::Set => C::Bool
    # Checks whether the given object is outdated due to dependencies.
    #
    # @param [Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The object
    #   whose outdatedness should be checked.
    #
    # @param [Set] processed The collection of items that has been visited
    #   during this outdatedness check. This is used to prevent checks for
    #   items that (indirectly) depend on their own from looping
    #   indefinitely. It should not be necessary to pass this a custom value.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
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
        dependency_causes_outdatedness?(dep) || outdated_due_to_dependencies?(dep.from, processed.merge([obj]))
      end

      # Cache
      @objects_outdated_due_to_dependencies[obj] = is_outdated

      # Done
      is_outdated
    end

    contract Nanoc::Int::DependencyStore::Dependency => C::Bool
    def dependency_causes_outdatedness?(dependency)
      return true if dependency.from.nil?

      status = basic_outdatedness_status_for(dependency.from)
      (status.active_props & dependency.active_props).any?
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::Bool
    # @param [Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The layout or item
    #   representation to check the rule memory for
    #
    # @return [Boolean] true if the rule memory for the given item
    #   represenation has changed, false otherwise
    def rule_memory_differs_for(obj)
      !rule_memory_store[obj].eql?(@action_provider.memory_for(obj).serialize)
    end
    memoize :rule_memory_differs_for

    contract C::Any => String
    # @param obj The object to create a checksum for
    #
    # @return [String] The digest
    def calc_checksum(obj)
      Nanoc::Int::Checksummer.calc(obj)
    end
    memoize :calc_checksum

    contract C::Any => C::Bool
    # @param obj
    #
    # @return [Boolean] false if either the new or the old checksum for the
    #   given object is not available, true if both checksums are available
    def checksums_available?(obj)
      checksum_store[obj] && calc_checksum(obj) ? true : false
    end
    memoize :checksums_available?

    contract C::Any => C::Bool
    # @param obj
    #
    # @return [Boolean] false if the old and new checksums for the given
    #   object differ, true if they are identical
    def checksums_identical?(obj)
      checksum_store[obj] == calc_checksum(obj)
    end
    memoize :checksums_identical?

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout] => C::Bool
    def content_checksums_identical?(obj)
      checksum_store.content_checksum_for(obj) == Nanoc::Int::Checksummer.calc_for_content_of(obj)
    end
    memoize :content_checksums_identical?

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout] => C::Bool
    def attributes_checksums_identical?(obj)
      checksum_store.attributes_checksum_for(obj) == Nanoc::Int::Checksummer.calc_for_attributes_of(obj)
    end
    memoize :attributes_checksums_identical?

    contract C::Any => C::Bool
    # @param obj
    #
    # @return [Boolean] true if the old and new checksums for the given object
    #   are available and identical, false otherwise
    def object_modified?(obj)
      !checksums_available?(obj) || !checksums_identical?(obj)
    end
    memoize :object_modified?
  end
end
