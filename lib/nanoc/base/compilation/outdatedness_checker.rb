# encoding: utf-8

module Nanoc

  # Responsible for determining whether an item or a layout is outdated.
  #
  # @api private
  class OutdatednessChecker

    extend Nanoc::Memoization

    def initialize(params={})
      @compiler = params[:compiler] or raise ArgumentError,
        'Nanoc::OutdatednessChecker#initialize needs a :compiler parameter'
      @checksum_store = params[:checksum_store] or raise ArgumentError,
        'Nanoc::OutdatednessChecker#initialize needs a :checksum_store parameter'
      @dependency_tracker = params[:dependency_tracker] or raise ArgumentError,
        'Nanoc::OutdatednessChecker#initialize needs a :dependency_tracker parameter'
      @item_rep_writer = params[:item_rep_writer] or raise ArgumentError,
        'Nanoc::OutdatednessChecker#initialize needs a :item_rep_writer parameter'
      @item_rep_store = params[:item_rep_store] or raise ArgumentError,
        'Nanoc::OutdatednessChecker#initialize needs a :item_rep_store parameter'

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

  protected

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
          if rule_memory_differs_for(obj)
            Nanoc::OutdatednessReasons::RulesModified
          elsif !checksums_available?(obj.item)
            Nanoc::OutdatednessReasons::NotEnoughData
          elsif !checksums_identical?(obj.item)
            Nanoc::OutdatednessReasons::SourceModified
          elsif (obj.raw_path && !@item_rep_writer.exist?(obj.raw_path))
            # FIXME this is not tested!
            Nanoc::OutdatednessReasons::NotWritten
          elsif obj.paths_without_snapshot.any? { |p| !@item_rep_writer.exist?(p) }
            Nanoc::OutdatednessReasons::NotWritten
          elsif @compiler.site.code_snippets.any? { |cs| object_modified?(cs) }
            Nanoc::OutdatednessReasons::CodeSnippetsModified
          elsif object_modified?(@compiler.site.config)
            Nanoc::OutdatednessReasons::ConfigurationModified
          else
            nil
          end
        when :item
          @item_rep_store.reps_for_item(obj).each do |rep|
            r = basic_outdatedness_reason_for(rep)
            return r unless r.nil?
          end
          nil
        when :layout
          if rule_memory_differs_for(obj)
            Nanoc::OutdatednessReasons::RulesModified
          elsif !checksums_available?(obj)
            Nanoc::OutdatednessReasons::NotEnoughData
          elsif !checksums_identical?(obj)
            Nanoc::OutdatednessReasons::SourceModified
          else
            nil
          end
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
      self.rule_memory_calculator.rule_memory_differs_for(obj)
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

    # TODO document
    def rule_memory_calculator
      @compiler.rule_memory_calculator
    end

    # @return [Nanoc::RulesCollection] The rules collection
    def rules_collection
      @compiler.rules_collection
    end

    # @return [Nanoc::DependencyTracker] The dependency tracker
    def dependency_tracker
      @dependency_tracker
    end

  end

end
