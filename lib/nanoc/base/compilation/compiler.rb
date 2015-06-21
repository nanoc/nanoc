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
  # * `visit_started` — indicates that the compiler requires content or
  #   attributes from the item representation that will be visited. Has one
  #   argument: the visited item identifier. This notification is used to
  #   track dependencies of items on other items; a `visit_started` event
  #   followed by another `visit_started` event indicates that the item
  #   corresponding to the former event will depend on the item from the
  #   latter event.
  #
  # * `visit_ended` — indicates that the compiler has finished visiting the
  #   item representation and that the requested attributes or content have
  #   been fetched (either successfully or with failure)
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
    extend Nanoc::Int::Memoization

    # @group Accessors

    # @return [Nanoc::Int::Site] The site this compiler belongs to
    attr_reader :site

    # The compilation stack. When the compiler begins compiling a rep or a
    # layout, it will be placed on the stack; when it is done compiling the
    # rep or layout, it will be removed from the stack.
    #
    # @return [Array] The compilation stack
    attr_reader :stack

    # @api private
    attr_reader :rules_collection

    # @api private
    attr_reader :compiled_content_cache

    # @api private
    attr_reader :checksum_store

    # @api private
    attr_reader :rule_memory_store

    # @api private
    attr_reader :rule_memory_calculator

    # @api private
    attr_reader :dependency_tracker

    # @group Public instance methods

    def initialize(site, rules_collection, compiled_content_cache:, checksum_store:, rule_memory_store:, rule_memory_calculator:)
      @site = site
      @rules_collection = rules_collection

      @compiled_content_cache = compiled_content_cache
      @checksum_store         = checksum_store
      @rule_memory_store      = rule_memory_store
      @rule_memory_calculator = rule_memory_calculator

      @dependency_tracker =
        Nanoc::Int::DependencyTracker.new(@site.items.to_a + @site.layouts.to_a)

      @stack = []
    end

    # 1. Load site
    # 2. Load rules
    # 3. Preprocess
    # 4. Build item reps
    # 5. Compile

    # TODO: move elsewhere
    def run_all
      # Preprocess
      Nanoc::Int::Preprocessor.new(site: @site, rules_collection: @rules_collection).run

      # Build reps
      reps = build_reps

      # Compile
      run(reps)
    end

    def run(reps)
      load_stores
      @site.freeze

      # Determine which reps need to be recompiled
      forget_dependencies_if_outdated

      @stack = []
      @dependency_tracker.start
      compile_reps(reps)
      @dependency_tracker.stop
      store(reps)
    ensure
      Nanoc::Int::TempFilenameFactory.instance.cleanup(
        Nanoc::Filter::TMP_BINARY_ITEMS_DIR)
      Nanoc::Int::TempFilenameFactory.instance.cleanup(
        Nanoc::Int::ItemRepWriter::TMP_TEXT_ITEMS_DIR)
    end

    # @group Private instance methods

    def load_stores
      stores.each(&:load)
    end

    # Store the modified helper data used for compiling the site.
    #
    # @return [void]
    def store(reps)
      # Calculate rule memory
      (reps.to_a + @site.layouts.to_a).each do |obj|
        rule_memory_store[obj] = rule_memory_calculator[obj]
      end

      # Calculate checksums
      objects.each do |obj|
        checksum_store[obj] = Nanoc::Int::Checksummer.calc(obj)
      end

      # Store
      stores.each(&:store)
    end

    # Returns all objects managed by the site (items, layouts, code snippets,
    # site configuration and the rules).
    #
    # @api private
    def objects
      site.items.to_a + site.layouts.to_a + site.code_snippets +
        [site.config, rules_collection]
    end

    def build_reps
      builder = Nanoc::Int::ItemRepBuilder.new(site, rules_collection)
      builder.run
      builder.reps
    end

    # @param [Nanoc::Int::ItemRep] rep The item representation for which the
    #   assigns should be fetched
    #
    # @return [Hash] The assigns that should be used in the next filter/layout
    #   operation
    #
    # @api private
    def assigns_for(rep)
      if rep.binary?
        content_or_filename_assigns = { filename: rep.snapshot_contents[:last].filename }
      else
        content_or_filename_assigns = { content: rep.snapshot_contents[:last].string }
      end

      # TODO: Do not expose @site (necessary for captures store though…)
      content_or_filename_assigns.merge({
        item: Nanoc::ItemView.new(rep.item, @reps),
        rep: Nanoc::ItemRepView.new(rep),
        item_rep: Nanoc::ItemRepView.new(rep),
        items: Nanoc::ItemCollectionView.new(site.items),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts),
        config: Nanoc::ConfigView.new(site.config),
        site: Nanoc::SiteView.new(site),
      })
    end

    # @return [Nanoc::Int::OutdatednessChecker] The outdatedness checker
    def outdatedness_checker
      Nanoc::Int::OutdatednessChecker.new(
        site: @site,
        checksum_store: checksum_store,
        dependency_tracker: @dependency_tracker,
        rules_collection: @rules_collection,
        rule_memory_store: @rule_memory_store,
        rule_memory_calculator: @rule_memory_calculator,
      )
    end
    memoize :outdatedness_checker

    private

    # Compiles the given representations.
    #
    # @param [Array] reps The item representations to compile.
    #
    # @return [void]
    def compile_reps(reps)
      # Listen to processing start/stop
      Nanoc::Int::NotificationCenter.on(:processing_started, self) { |obj| @stack.push(obj) }
      Nanoc::Int::NotificationCenter.on(:processing_ended,   self) { |_obj| @stack.pop       }

      # Assign snapshots
      reps.each do |rep|
        rep.snapshot_defs = rule_memory_calculator.snapshots_defs_for(rep)
      end

      # Find item reps to compile and compile them
      selector = Nanoc::Int::ItemRepSelector.new(reps.to_a)
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
      Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
      Nanoc::Int::NotificationCenter.post(:processing_started,  rep)
      Nanoc::Int::NotificationCenter.post(:visit_started,       rep.item)

      if can_reuse_content_for_rep?(rep)
        Nanoc::Int::NotificationCenter.post(:cached_content_used, rep)
        rep.snapshot_contents = compiled_content_cache[rep]
      else
        recalculate_content_for_rep(rep)
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
      Nanoc::Int::NotificationCenter.post(:visit_ended,       rep.item)
    end

    # @return [Boolean]
    def can_reuse_content_for_rep?(rep)
      !rep.item.forced_outdated? && !outdatedness_checker.outdated?(rep) && compiled_content_cache[rep]
    end

    # @return [void]
    def recalculate_content_for_rep(rep)
      executor = Nanoc::Int::Executor.new(self)

      executor.snapshot(rep, :raw)
      executor.snapshot(rep, :pre, final: false)
      rules_collection.compilation_rule_for(rep)
        .apply_to(rep, executor: executor, site: @site)
      executor.snapshot(rep, :post) if rep.has_snapshot?(:post)
      executor.snapshot(rep, :last)
    end

    # Clears the list of dependencies for items that will be recompiled.
    #
    # @param [Array<Nanoc::Int::Item>] items The list of items for which to forget
    #   the dependencies
    #
    # @return [void]
    def forget_dependencies_if_outdated
      @site.items.each do |i|
        if i.reps.any? { |r| outdatedness_checker.outdated?(r) }
          @dependency_tracker.forget_dependencies_for(i)
        end
      end
    end

    # Returns all stores that can load/store data that can be used for
    # compilation.
    def stores
      [
        checksum_store,
        compiled_content_cache,
        @dependency_tracker,
        rule_memory_store,
      ]
    end
  end
end
