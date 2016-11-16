module Nanoc::Int
  # Responsible for compiling a site’s item representations.
  #
  # The compilation process makes use of notifications (see
  # {Nanoc::Int::NotificationCenter}) to track dependencies between items,
  # layouts, etc. The following notifications are used:
  #
  # * `compilation_started` — indicates that the compiler has started
  #   compiling this item representation. Has one argument: the item
  #   representation itself. Only one item can be compiled at a given moment;
  #   therefore, it is not possible to get two consecutive
  #   `compilation_started` notifications without also getting a
  #   `compilation_ended` notification in between them.
  #
  # * `compilation_ended` — indicates that the compiler has finished compiling
  #   this item representation (either successfully or with failure). Has one
  #   argument: the item representation itself.
  #
  # * `processing_started` — indicates that the compiler has started
  #   processing the specified object, which can be an item representation
  #   (when it is compiled) or a layout (when it is used to lay out an item
  #   representation or when it is used as a partial)
  #
  # * `processing_ended` — indicates that the compiler has finished processing
  #   the specified object.
  #
  # @api private
  class Compiler
    # @api private
    attr_reader :site

    # The compilation stack. When the compiler begins compiling a rep or a
    # layout, it will be placed on the stack; when it is done compiling the
    # rep or layout, it will be removed from the stack.
    #
    # @return [Array] The compilation stack
    attr_reader :stack

    # @api private
    attr_reader :compiled_content_cache

    # @api private
    attr_reader :checksum_store

    # @api private
    attr_reader :rule_memory_store

    # @api private
    attr_reader :action_provider

    # @api private
    attr_reader :dependency_store

    # @api private
    attr_reader :outdatedness_checker

    # @api private
    attr_reader :reps

    def initialize(site, compiled_content_cache:, checksum_store:, rule_memory_store:, action_provider:, dependency_store:, outdatedness_checker:, reps:)
      @site = site

      @compiled_content_cache = compiled_content_cache
      @checksum_store         = checksum_store
      @rule_memory_store      = rule_memory_store
      @dependency_store       = dependency_store
      @outdatedness_checker   = outdatedness_checker
      @reps                   = reps
      @action_provider        = action_provider

      @stack = []
    end

    def run_all
      @action_provider.preprocess(@site)
      build_reps
      prune
      run
      @action_provider.postprocess(@site, @reps)
    end

    def run
      load_stores
      @site.freeze

      # Determine which reps need to be recompiled
      forget_dependencies_if_outdated

      @stack = []
      compile_reps
      store
    ensure
      Nanoc::Int::TempFilenameFactory.instance.cleanup(
        Nanoc::Filter::TMP_BINARY_ITEMS_DIR,
      )
      Nanoc::Int::TempFilenameFactory.instance.cleanup(
        Nanoc::Int::ItemRepWriter::TMP_TEXT_ITEMS_DIR,
      )
    end

    def load_stores
      # FIXME: icky hack to update the dependency store’s list of objects
      # (does not include preprocessed objects otherwise)
      dependency_store.objects = site.items.to_a + site.layouts.to_a

      stores.each(&:load)
    end

    # Store the modified helper data used for compiling the site.
    #
    # @return [void]
    def store
      # Calculate rule memory
      (@reps.to_a + @site.layouts.to_a).each do |obj|
        rule_memory_store[obj] = action_provider.memory_for(obj).serialize
      end

      # Calculate checksums
      objects_to_checksum =
        site.items.to_a + site.layouts.to_a + site.code_snippets + [site.config]
      objects_to_checksum.each do |obj|
        checksum_store[obj] = Nanoc::Int::Checksummer.calc(obj)
      end

      # Store
      stores.each(&:store)
    end

    def build_reps
      builder = Nanoc::Int::ItemRepBuilder.new(
        site, action_provider, @reps
      )
      builder.run
    end

    # @param [Nanoc::Int::ItemRep] rep The item representation for which the
    #   assigns should be fetched
    #
    # @return [Hash] The assigns that should be used in the next filter/layout
    #   operation
    #
    # @api private
    def assigns_for(rep, dependency_tracker)
      content_or_filename_assigns =
        if rep.binary?
          { filename: rep.snapshot_contents[:last].filename }
        else
          { content: rep.snapshot_contents[:last].string }
        end

      view_context = create_view_context(dependency_tracker)

      content_or_filename_assigns.merge(
        item: Nanoc::ItemWithRepsView.new(rep.item, view_context),
        rep: Nanoc::ItemRepView.new(rep, view_context),
        item_rep: Nanoc::ItemRepView.new(rep, view_context),
        items: Nanoc::ItemCollectionWithRepsView.new(site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::ConfigView.new(site.config, view_context),
      )
    end

    def create_view_context(dependency_tracker)
      Nanoc::ViewContext.new(
        reps: @reps,
        items: @site.items,
        dependency_tracker: dependency_tracker,
        compiler: self,
      )
    end

    # @api private
    def filter_name_and_args_for_layout(layout)
      mem = action_provider.memory_for(layout)
      if mem.nil? || mem.size != 1 || !mem[0].is_a?(Nanoc::Int::RuleMemoryActions::Filter)
        # FIXME: Provide a nicer error message
        raise Nanoc::Int::Errors::Generic, "No rule memory found for #{layout.identifier}"
      end
      [mem[0].filter_name, mem[0].params]
    end

    private

    def prune
      if site.config[:prune][:auto_prune]
        Nanoc::Pruner.new(site.config, reps, exclude: prune_config_exclude).run
      end
    end

    def prune_config
      site.config[:prune] || {}
    end

    def prune_config_exclude
      prune_config[:exclude] || {}
    end

    def compile_reps
      # Listen to processing start/stop
      Nanoc::Int::NotificationCenter.on(:processing_started, self) { |obj| @stack.push(obj) }
      Nanoc::Int::NotificationCenter.on(:processing_ended, self) { |_obj| @stack.pop }

      # Assign snapshots
      @reps.each do |rep|
        rep.snapshot_defs = action_provider.snapshots_defs_for(rep)
      end

      # Find item reps to compile
      outdated_reps = @reps.select { |r| outdatedness_checker.outdated?(r) }
      outdated_reps.each { |r| puts "+++ Found outdated rep to recompile: #{r.inspect}" }
      dependent_items = outdated_reps.flat_map { |r| @dependency_store.objects_needed_for_compiled_content_of(r.item) }
      dependent_items.each { |i| puts "+++ Found dependent item to recompile: #{i.inspect}" }
      dependent_reps = dependent_items.flat_map { |i| @reps[i] }
      dependent_reps.each { |r| puts "+++ Found dependent rep to recompile: #{r.inspect}" }
      reps_to_compile = Set.new(outdated_reps + dependent_reps)

      # Compile
      selector = Nanoc::Int::ItemRepSelector.new(reps_to_compile, @dependency_store)
      selector.each do |rep|
        @stack = []
        compile_rep(rep)
      end
    ensure
      Nanoc::Int::NotificationCenter.remove(:processing_started, self)
      Nanoc::Int::NotificationCenter.remove(:processing_ended,   self)
    end

    # Compiles the given item representation.
    #
    # This method should not be called directly; please use
    # {Nanoc::Int::Compiler#run} instead, and pass this item representation's item
    # as its first argument.
    #
    # @param [Nanoc::Int::ItemRep] rep The rep that is to be compiled
    #
    # @return [void]
    def compile_rep(rep)
      dependency_tracker = Nanoc::Int::DependencyTracker.new(@dependency_store)

      Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
      Nanoc::Int::NotificationCenter.post(:processing_started,  rep)
      dependency_tracker.enter(rep.item)

      if can_reuse_content_for_rep?(rep)
        Nanoc::Int::NotificationCenter.post(:cached_content_used, rep)
        rep.snapshot_contents = compiled_content_cache[rep]
      else
        recalculate_content_for_rep(rep, dependency_tracker)
      end

      rep.compiled = true
      compiled_content_cache[rep] = rep.snapshot_contents

      Nanoc::Int::NotificationCenter.post(:processing_ended,  rep)
      Nanoc::Int::NotificationCenter.post(:compilation_ended, rep)
    rescue => e
      rep.forget_progress
      Nanoc::Int::NotificationCenter.post(:compilation_failed, rep, e)
      raise e
    ensure
      dependency_tracker.exit(rep.item)
    end

    # @return [Boolean]
    def can_reuse_content_for_rep?(rep)
      !outdatedness_checker.outdated?(rep) && compiled_content_cache[rep]
    end

    # @return [void]
    def recalculate_content_for_rep(rep, dependency_tracker)
      executor = Nanoc::Int::Executor.new(self, dependency_tracker)

      action_provider.memory_for(rep).each do |action|
        case action
        when Nanoc::Int::RuleMemoryActions::Filter
          executor.filter(rep, action.filter_name, action.params)
        when Nanoc::Int::RuleMemoryActions::Layout
          executor.layout(rep, action.layout_identifier, action.params)
        when Nanoc::Int::RuleMemoryActions::Snapshot
          executor.snapshot(rep, action.snapshot_name, final: action.final?, path: action.path)
        else
          raise "Internal inconsistency: unknown action #{action.inspect}"
        end
      end
    end

    # Clears the list of dependencies for items that will be recompiled.
    #
    # @return [void]
    def forget_dependencies_if_outdated
      @site.items.each do |i|
        if @reps[i].any? { |r| outdatedness_checker.outdated?(r) }
          @dependency_store.forget_dependencies_for(i)
        end
      end
    end

    # Returns all stores that can load/store data that can be used for
    # compilation.
    def stores
      [
        checksum_store,
        compiled_content_cache,
        @dependency_store,
        rule_memory_store,
      ]
    end
  end
end
