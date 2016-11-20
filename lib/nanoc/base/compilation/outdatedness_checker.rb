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

    class Details
      attr_reader :reason

      def initialize(reason:, raw_content: false, attributes: false, compiled_content: false, path: false)
        @reason = reason
        @raw_content = raw_content
        @attributes = attributes
        @compiled_content = compiled_content
        @path = path
      end

      # item, item rep, layout
      def raw_content_outdated?
        @raw_content
      end

      # item, item rep, layout
      def attributes_outdated?
        @attributes
      end

      # item, item rep, layout
      def compiled_content_outdated?
        @compiled_content
      end

      # item, item rep
      def path_outdated?
        @path
      end
    end

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

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::Maybe[Details]
    def basic_outdatedness_details_for(obj)
      case obj
      when Nanoc::Int::ItemRep
        # Outdated if rules are outdated
        if rule_memory_differs_for(obj)
          return Details.new(
            reason: Reasons::RulesModified,
            compiled_content: true,
            path: true,
          )
        end

        # Outdated if checksums are missing
        unless checksums_available?(obj.item)
          return Details.new(
            reason: Reasons::NotEnoughData,
            raw_content: true,
            attributes: true,
            compiled_content: true,
            path: true,
          )
        end

        # Outdated if content checksums are different
        unless content_checksums_identical?(obj.item)
          return Details.new(
            reason: Reasons::ContentModified,
            raw_content: true,
            attributes: true,
            compiled_content: true,
            path: false, # FIXME
          )
        end

        # Outdated if attributes checksums are different
        unless attributes_checksums_identical?(obj.item)
          return Details.new(
            reason: Reasons::AttributesModified,
            raw_content: true,
            attributes: true,
            compiled_content: true,
            path: false, # FIXME
          )
        end

        # Outdated if compiled file doesn't exist (yet)
        if obj.raw_path && !File.file?(obj.raw_path)
          return Details.new(
            reason: Reasons::NotWritten,
            compiled_content: true,
          )
        end

        # Outdated if code snippets outdated
        if site.code_snippets.any? { |cs| object_modified?(cs) }
          return Details.new(
            reason: Reasons::CodeSnippetsModified,
            raw_content: true,
            attributes: true,
            compiled_content: true,
            path: true,
          )
        end

        # Outdated if configuration outdated
        if object_modified?(site.config)
          return Details.new(
            reason: Reasons::ConfigurationModified,
            compiled_content: true,
            path: true,
          )
        end

        # Not outdated
        nil
      when Nanoc::Int::Item
        # TODO: find all, then OR them together
        @reps[obj].lazy.map { |rep| basic_outdatedness_details_for(rep) }.find { |d| d }
      when Nanoc::Int::Layout
        # Outdated if rules outdated
        if rule_memory_differs_for(obj)
          return Details.new(
            reason: Reasons::RulesModified,
            compiled_content: true,
          )
        end

        # Outdated if checksums are missing
        unless checksums_available?(obj)
          return Details.new(
            reason: Reasons::NotEnoughData,
            raw_content: true,
            attributes: true,
          )
        end

        # Outdated if content checksums are different
        unless content_checksums_identical?(obj)
          return Details.new(
            reason: Reasons::ContentModified,
            raw_content: true,
            attributes: true,
          )
        end

        # Outdated if attributes checksums are different
        unless attributes_checksums_identical?(obj)
          return Details.new(
            reason: Reasons::AttributesModified,
            raw_content: true,
            attributes: true,
          )
        end

        # Not outdated
        nil
      else
        raise "do not know how to check outdatedness of #{obj.inspect}"
      end
    end
    memoize :basic_outdatedness_details_for

    def basic_outdatedness_reason_for(obj)
      details = basic_outdatedness_details_for(obj)
      details ? details.reason : nil
    end

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
      is_outdated = dependency_store.dependencies_causing_outdatedness_of(obj).any? do |dependency|
        other = dependency.from

        if other.nil?
          true
        else
          basic_details = basic_outdatedness_details_for(other)
          # p [obj, other, basic_details, dependency]
          dependency_matches =
            basic_details && (
              (basic_details.raw_content_outdated? && dependency.raw_content?) ||
              (basic_details.attributes_outdated? && dependency.attributes?) ||
              (basic_details.compiled_content_outdated? && dependency.compiled_content?) ||
              (basic_details.path_outdated? && dependency.path?)
            )

          red = "\e[31m"
          green = "\e[32m"
          reset = "\e[0m"

          p [obj, other]
          print(dependency_matches ? red : green)
          puts "dependency_matches=#{dependency_matches}"
          print reset

          outdated_due_to_dependencies = outdated_due_to_dependencies?(other, processed.merge([obj]))
          print(outdated_due_to_dependencies ? red : green)
          puts "outdated_due_to_dependencies=#{outdated_due_to_dependencies}"
          print reset
          puts

          dependency_matches || outdated_due_to_dependencies
        end
      end

      # Cache
      @objects_outdated_due_to_dependencies[obj] = is_outdated

      # Done
      is_outdated
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
