# encoding: utf-8

module Nanoc3

  # Responsible for determining whether an item or a layout is outdated.
  #
  # @api private
  class OutdatednessChecker

    # @option params [Nanoc3::Site] :site (nil) The site this outdatedness
    #   checker belongs to.
    #
    # @option params [Nanoc3::ChecksumStore] :checksum_store (nil) The
    #   checksum store where checksums of items, layouts, … are stored.
    #
    # @option params [Nanoc3::DependencyTracker] :dependency_tracker (nil) The
    #   dependency tracker for the given site.
    def initialize(params={})
      @site = params[:site] or raise ArgumentError,
        'Nanoc3::OutdatednessChecker#initialize needs a :site parameter'
      @checksum_store = params[:checksum_store] or raise ArgumentError,
        'Nanoc3::OutdatednessChecker#initialize needs a :checksum_store parameter'
      @dependency_tracker = params[:dependency_tracker] or raise ArgumentError,
        'Nanoc3::OutdatednessChecker#initialize needs a :dependency_tracker parameter'

      @basic_outdatedness_reasons = {}
      @outdatedness_reasons = {}
      @objects_outdated_due_to_dependencies = {}
    end

    # Checks whether the given object is outdated and therefore needs to be
    # recompiled.
    #
    # @param [Nanoc3::Item, Nanoc3::ItemRep, Nanoc3::Layout] obj The object
    #   whose outdatedness should be checked.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def outdated?(obj)
      !outdatedness_reason_for(obj).nil?
    end

    # Calculates the reason why the given object is outdated.
    #
    # @param [Nanoc3::Item, Nanoc3::ItemRep, Nanoc3::Layout] obj The object
    #   whose outdatedness reason should be calculated.
    #
    # @return [Nanoc3::OutdatednessReasons::Generic, nil] The reason why the
    #   given object is outdated, or nil if the object is not outdated.
    def outdatedness_reason_for(obj)
      # Get from cache
      if @outdatedness_reasons.has_key?(obj)
        return @outdatedness_reasons[obj]
      end

      # Calculate
      reason = basic_outdatedness_reason_for(obj)
      if reason.nil? && outdated_due_to_dependencies?(obj)
        reason = Nanoc3::OutdatednessReasons::DependenciesOutdated
      end

      # Cache
      @outdatedness_reasons[obj] = reason

      # Done
      reason
    end

  private

    # Checks whether the given object is outdated and therefore needs to be
    # recompiled. This method does not take dependencies into account; use
    # {#outdated?} if you want to include dependencies in the outdatedness
    # check.
    #
    # @param [Nanoc3::Item, Nanoc3::ItemRep, Nanoc3::Layout] obj The object
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
    # @param [Nanoc3::Item, Nanoc3::ItemRep, Nanoc3::Layout] obj The object
    #   whose outdatedness reason should be calculated.
    #
    # @return [Nanoc3::OutdatednessReasons::Generic, nil] The reason why the
    #   given object is outdated, or nil if the object is not outdated.
    def basic_outdatedness_reason_for(obj)
      # Get from cache
      if @basic_outdatedness_reasons.has_key?(obj)
        return @basic_outdatedness_reasons[obj]
      end

      # Calculate
      reason = case obj.type
        when :item_rep
          # Outdated if checksums are missing or different
          return Nanoc3::OutdatednessReasons::NotEnoughData if !checksum_store.checksums_available?(obj.item)
          return Nanoc3::OutdatednessReasons::SourceModified if !checksum_store.checksums_identical?(obj.item)

          # Outdated if compiled file doesn't exist (yet)
          return Nanoc3::OutdatednessReasons::NotWritten if obj.raw_path && !File.file?(obj.raw_path)

          # Outdated if code snippets outdated
          return Nanoc3::OutdatednessReasons::CodeSnippetsModified if site.code_snippets.any? do |cs|
            checksum_store.object_modified?(cs)
          end

          # Outdated if configuration outdated
          return Nanoc3::OutdatednessReasons::ConfigurationModified if checksum_store.object_modified?(site.config)

          # Outdated if rules outdated
          return Nanoc3::OutdatednessReasons::RulesModified if
            checksum_store.object_modified?(site.compiler.rules_with_reference)

          # Not outdated
          return nil
        when :item
          obj.reps.find { |rep| outdatedness_reason_for(rep) }
        when :layout
          # Outdated if checksums are missing or different
          return Nanoc3::OutdatednessReasons::NotEnoughData if !checksum_store.checksums_available?(obj)
          return Nanoc3::OutdatednessReasons::SourceModified if !checksum_store.checksums_identical?(obj)

          # Not outdated
          return nil
        else
          raise RuntimeError, "do not know how to check outdatedness of #{obj.inspect}"
      end

      # Cache
      @basic_outdatedness_reasons[obj] = reason

      # Done
      reason
    end

    # Checks whether the given object is outdated due to dependencies.
    #
    # @param [Nanoc3::Item, Nanoc3::ItemRep, Nanoc3::Layout] obj The object
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
      return true if processed.include?(obj)

      # Calculate
      if $loud
        STDOUT.puts
        STDOUT.puts "direct predecessors of #{obj.inspect}:"
        dependency_tracker.direct_predecessors_of(obj).each do |o|
          STDOUT.puts '- ' + o.inspect
        end
      end
      is_outdated = dependency_tracker.direct_predecessors_of(obj).any? do |other|
        other.nil? || basic_outdated?(other) || outdated_due_to_dependencies?(other, processed.merge([obj]))
      end

      # Cache
      @objects_outdated_due_to_dependencies[obj] = is_outdated

      # Done
      is_outdated
    end

    # @return [Nanoc3::ChecksumStore] The checksum store
    def checksum_store
      @checksum_store
    end

    # @return [Nanoc3::DependencyTracker] The dependency tracker
    def dependency_tracker
      @dependency_tracker
    end

    # @return [Nanoc3::Site] The site
    def site
      @site
    end

  end

end
