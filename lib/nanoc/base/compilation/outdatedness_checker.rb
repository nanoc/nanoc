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
      case obj
      when Nanoc::Int::ItemRep
        # Outdated if rules outdated
        return Reasons::RulesModified if
          rule_memory_differs_for(obj)

        # Outdated if checksums are missing or different
        return Reasons::NotEnoughData unless checksums_available?(obj.item)
        return Reasons::SourceModified unless checksums_identical?(obj.item)

        # Outdated if compiled file doesn't exist (yet)
        return Reasons::NotWritten if obj.raw_path && !File.file?(obj.raw_path)

        # Outdated if code snippets outdated
        return Reasons::CodeSnippetsModified if site.code_snippets.any? do |cs|
          object_modified?(cs)
        end

        # Outdated if configuration outdated
        return Reasons::ConfigurationModified if object_modified?(site.config)

        # Not outdated
        nil
      when Nanoc::Int::Item
        @reps[obj].lazy.map { |rep| basic_outdatedness_reason_for(rep) }.find { |s| s }
      when Nanoc::Int::Layout
        # Outdated if rules outdated
        return Reasons::RulesModified if
          rule_memory_differs_for(obj)

        # Outdated if checksums are missing or different
        return Reasons::NotEnoughData unless checksums_available?(obj)
        return Reasons::SourceModified unless checksums_identical?(obj)

        # Not outdated
        nil
      else
        raise "do not know how to check outdatedness of #{obj.inspect}"
      end
    end
    memoize :basic_outdatedness_reason_for

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
      is_outdated = dependency_store.objects_causing_outdatedness_of(obj).any? do |other|
        other.nil? || basic_outdated?(other) || outdated_due_to_dependencies?(other, processed.merge([obj]))
      end

      # Cache
      @objects_outdated_due_to_dependencies[obj] = is_outdated

      # Done
      is_outdated
    end

    # @param [Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The layout or item
    #   representation to check the rule memory for
    #
    # @return [Boolean] true if the rule memory for the given item
    #   represenation has changed, false otherwise
    def rule_memory_differs_for(obj)
      !rule_memory_store[obj].eql?(@action_provider.memory_for(obj).serialize)
    end
    memoize :rule_memory_differs_for

    # @param obj The object to create a checksum for
    #
    # @return [String] The digest
    def calc_checksum(obj)
      Nanoc::Int::Checksummer.calc(obj)
    end
    memoize :calc_checksum

    # @param obj
    #
    # @return [Boolean] false if either the new or the old checksum for the
    #   given object is not available, true if both checksums are available
    def checksums_available?(obj)
      checksum_store[obj] && calc_checksum(obj)
    end
    memoize :checksums_available?

    # @param obj
    #
    # @return [Boolean] false if the old and new checksums for the given
    #   object differ, true if they are identical
    def checksums_identical?(obj)
      checksum_store[obj] == calc_checksum(obj)
    end
    memoize :checksums_identical?

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
