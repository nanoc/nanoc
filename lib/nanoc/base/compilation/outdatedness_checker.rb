# encoding: utf-8

module Nanoc

  # Responsible for determining whether an item or a layout is outdated.
  #
  # @api private
  class OutdatednessChecker

    extend Nanoc::Memoization

    # @option params [Nanoc::Site] :site (nil) The site this outdatedness
    #   checker belongs to.
    #
    # @option params [Nanoc::ChecksumStore] :checksum_store (nil) The
    #   checksum store where checksums of items, layouts, … are stored.
    #
    # @option params [Nanoc::DependencyTracker] :dependency_tracker (nil) The
    #   dependency tracker for the given site.
    def initialize(params={})
      @site = params[:site] or raise ArgumentError,
        'Nanoc::OutdatednessChecker#initialize needs a :site parameter'
      @checksum_store = params[:checksum_store] or raise ArgumentError,
        'Nanoc::OutdatednessChecker#initialize needs a :checksum_store parameter'
      @dependency_tracker = params[:dependency_tracker] or raise ArgumentError,
        'Nanoc::OutdatednessChecker#initialize needs a :dependency_tracker parameter'

      @basic_outdatedness_reasons = {}
      @outdatedness_reasons = {}
      @objects_outdated_due_to_dependencies = {}
    end

    # Checks whether the given object is outdated and therefore needs to be
    # recompiled.
    #
    # @param [Nanoc::Item, Nanoc::ItemRep, Nanoc::Layout] obj The object
    #   whose outdatedness should be checked.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def outdated?(obj)
      !outdatedness_reason_for(obj).nil?
    end

    # Calculates the reason why the given object is outdated.
    #
    # @param [Nanoc::Item, Nanoc::ItemRep, Nanoc::Layout] obj The object
    #   whose outdatedness reason should be calculated.
    #
    # @return [Nanoc::OutdatednessReasons::Generic, nil] The reason why the
    #   given object is outdated, or nil if the object is not outdated.
    def outdatedness_reason_for(obj)
      reason = basic_outdatedness_reason_for(obj)
      if reason.nil? && outdated_due_to_dependencies?(obj)
        reason = Nanoc::OutdatednessReasons::DependenciesOutdated
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
    # @param [Nanoc::Item, Nanoc::ItemRep, Nanoc::Layout] obj The object
    #   whose outdatedness should be checked.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def basic_outdated?(obj)
      !basic_outdatedness_reason_for(obj).nil?
    end

    # Calculates the reason why the given object is outdated. This method does
    # not take dependencies into account; use {#outdatedness_reason_for?} if
    # you want to include dependencies in the outdatedness check.
    #
    # @param [Nanoc::Item, Nanoc::ItemRep, Nanoc::Layout] obj The object
    #   whose outdatedness reason should be calculated.
    #
    # @return [Nanoc::OutdatednessReasons::Generic, nil] The reason why the
    #   given object is outdated, or nil if the object is not outdated.
    def basic_outdatedness_reason_for(obj)
      case obj.type
        when :item_rep
          # Outdated if rules outdated
          return Nanoc::OutdatednessReasons::RulesModified if
            rule_memory_differs_for(obj)

          # Outdated if checksums are missing or different
          return Nanoc::OutdatednessReasons::NotEnoughData if !checksums_available?(obj.item)
          return Nanoc::OutdatednessReasons::SourceModified if !checksums_identical?(obj.item)

          # Outdated if compiled file doesn't exist (yet)
          return Nanoc::OutdatednessReasons::NotWritten if obj.raw_path && !File.file?(obj.raw_path)

          # Outdated if code snippets outdated
          return Nanoc::OutdatednessReasons::CodeSnippetsModified if site.code_snippets.any? do |cs|
            object_modified?(cs)
          end

          # Outdated if configuration outdated
          return Nanoc::OutdatednessReasons::ConfigurationModified if object_modified?(site.config)

          # Not outdated
          return nil
        when :item
          obj.reps.find { |rep| basic_outdatedness_reason_for(rep) }
        when :layout
          # Outdated if rules outdated
          return Nanoc::OutdatednessReasons::RulesModified if
            rule_memory_differs_for(obj)

          # Outdated if checksums are missing or different
          return Nanoc::OutdatednessReasons::NotEnoughData if !checksums_available?(obj)
          return Nanoc::OutdatednessReasons::SourceModified if !checksums_identical?(obj)

          # Not outdated
          return nil
        else
          raise RuntimeError, "do not know how to check outdatedness of #{obj.inspect}"
      end
    end
    memoize :basic_outdatedness_reason_for

    # Checks whether the given object is outdated due to dependencies.
    #
    # @param [Nanoc::Item, Nanoc::ItemRep, Nanoc::Layout] obj The object
    #   whose outdatedness should be checked.
    #
    # @param [Set] processed The collection of items that has been visited
    #   during this outdatedness check. This is used to prevent checks for
    #   items that (indirectly) depend on their own from looping
    #   indefinitely. It should not be necessary to pass this a custom value.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def outdated_due_to_dependencies?(obj, processed=Set.new)
      # Convert from rep to item if necessary
      obj = obj.item if obj.type == :item_rep

      # Get from cache
      if @objects_outdated_due_to_dependencies.has_key?(obj)
        return @objects_outdated_due_to_dependencies[obj]
      end

      # Check processed
      # Don’t return true; the false will be or’ed into a true if there
      # really is a dependency that is causing outdatedness.
      return false if processed.include?(obj)

      # Calculate
      is_outdated = dependency_tracker.objects_causing_outdatedness_of(obj).any? do |other|
        other.nil? || basic_outdated?(other) || outdated_due_to_dependencies?(other, processed.merge([obj]))
      end

      # Cache
      @objects_outdated_due_to_dependencies[obj] = is_outdated

      # Done
      is_outdated
    end

    # @param [Nanoc::ItemRep, Nanoc::Layout] obj The layout or item
    #   representation to check the rule memory for
    #
    # @return [Boolean] true if the rule memory for the given item
    #   represenation has changed, false otherwise
    def rule_memory_differs_for(obj)
      rules_collection.rule_memory_differs_for(obj)
    end
    memoize :rule_memory_differs_for

    # @param obj
    #
    # @return [Boolean] false if either the new or the old checksum for the
    #   given object is not available, true if both checksums are available
    def checksums_available?(obj)
      !!checksum_store[obj] && obj.checksum
    end
    memoize :checksums_available?

    # @param obj
    #
    # @return [Boolean] false if the old and new checksums for the given
    #   object differ, true if they are identical
    def checksums_identical?(obj)
      checksum_store[obj] == obj.checksum
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

    # @return [Nanoc::ChecksumStore] The checksum store
    def checksum_store
      @checksum_store
    end

    # @return [Nanoc::RulesCollection] The rules collection
    def rules_collection
      site.compiler.rules_collection
    end

    # @return [Nanoc::DependencyTracker] The dependency tracker
    def dependency_tracker
      @dependency_tracker
    end

    # @return [Nanoc::Site] The site
    def site
      @site
    end

  end

end
