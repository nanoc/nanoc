# encoding: utf-8

module Nanoc

  # Responsible for compiling a site’s item representations.
  #
  # The compilation process makes use of notifications (see
  # {Nanoc::NotificationCenter}) to track dependencies between items,
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
  class Compiler

    extend Nanoc::Memoization

    # @group Accessors

    # @return [Nanoc::Site] The site this compiler belongs to
    attr_reader :site

    # The compilation stack. When the compiler begins compiling a rep or a
    # layout, it will be placed on the stack; when it is done compiling the
    # rep or layout, it will be removed from the stack.
    #
    # @return [Array] The compilation stack
    attr_reader :stack

    # @group Public instance methods

    # Creates a new compiler fo the given site
    #
    # @param [Nanoc::Site] site The site this compiler belongs to
    def initialize(site)
      @site = site

      @stack = []
    end

    # Compiles the site and writes out the compiled item representations.
    #
    # Previous versions of nanoc (< 3.2) allowed passing items to compile, and
    # had a “force” option to make the compiler recompile all pages, even
    # when not outdated. These arguments and options are, as of nanoc 3.2, no
    # longer used, and will simply be ignored when passed to {#run}.
    #
    # @overload run
    #   @return [void]
    def run(*args)
      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Compile reps
      load
      @site.freeze
      dependency_tracker.start
      compile_reps(reps)
      dependency_tracker.stop
      store
    ensure
      # Cleanup
      FileUtils.rm_rf(Nanoc::Filter::TMP_BINARY_ITEMS_DIR)
    end

    # @group Private instance methods

    # @return [Nanoc::RulesCollection] The collection of rules to be used
    #   for compiling this site
    def rules_collection
      Nanoc::RulesCollection.new(self)
    end
    memoize :rules_collection

    # Load the helper data that is used for compiling the site.
    #
    # @api private
    #
    # @return [void]
    def load
      return if @loaded || @loading
      @loading = true

      # Load site if necessary
      site.load

      # Preprocess
      rules_collection.load
      preprocess
      site.setup_child_parent_links
      build_reps
      route_reps

      # Load auxiliary stores
      stores.each { |s| s.load }

      # Determine which reps need to be recompiled
      forget_dependencies_if_outdated(items)

      @loaded = true
    rescue => e
      unload
      raise e
    ensure
      @loading = false
    end

    # Undoes the effects of {#load}. Used when {#load} raises an exception.
    #
    # @api private
    #
    # @return [void]
    def unload
      return if @unloading
      @unloading = true

      stores.each { |s| s.unload }

      @stack = []

      items.each { |item| item.reps.clear }
      site.teardown_child_parent_links
      rules_collection.unload

      site.unload

      @loaded = false
      @unloading = false
    end

    # Store the modified helper data used for compiling the site.
    #
    # @api private
    #
    # @return [void]
    def store
      # Calculate rule memory
      (reps + layouts).each do |obj|
        rule_memory_store[obj] = rule_memory_calculator[obj]
      end

      # Calculate checksums
      self.objects.each do |obj|
        checksum_store[obj] = obj.checksum
      end

      # Store
      stores.each { |s| s.store }
    end

    # Returns the dependency tracker for this site, creating it first if it
    # does not yet exist.
    #
    # @api private
    #
    # @return [Nanoc::DependencyTracker] The dependency tracker for this site
    def dependency_tracker
      dt = Nanoc::DependencyTracker.new(@site.items + @site.layouts)
      dt.compiler = self
      dt
    end
    memoize :dependency_tracker

    # Runs the preprocessor.
    #
    # @api private
    def preprocess
      return if rules_collection.preprocessor.nil?
      preprocessor_context.instance_eval(&rules_collection.preprocessor)
    end

    # Returns all objects managed by the site (items, layouts, code snippets,
    # site configuration and the rules).
    #
    # @api private
    def objects
      site.items + site.layouts + site.code_snippets +
        [ site.config, rules_collection ]
    end

    # Creates the representations of all items as defined by the compilation
    # rules.
    #
    # @api private
    def build_reps
      items.each do |item|
        # Find matching rules
        matching_rules = rules_collection.item_compilation_rules_for(item)
        raise Nanoc::Errors::NoMatchingCompilationRuleFound.new(item) if matching_rules.empty?

        # Create reps
        rep_names = matching_rules.map { |r| r.rep_name }.uniq
        rep_names.each do |rep_name|
          item.reps << ItemRep.new(item, rep_name)
        end
      end
    end

    # Determines the paths of all item representations.
    #
    # @api private
    def route_reps
      reps.each do |rep|
        # Find matching rules
        rules = rules_collection.routing_rules_for(rep)
        raise Nanoc::Errors::NoMatchingRoutingRuleFound.new(rep) if rules[:last].nil?

        rules.each_pair do |snapshot, rule|
          # Get basic path by applying matching rule
          basic_path = rule.apply_to(rep, :compiler => self)
          next if basic_path.nil?
          if basic_path !~ %r{^/}
            raise RuntimeError, "The path returned for the #{rep.inspect} item representation, “#{basic_path}”, does not start with a slash. Please ensure that all routing rules return a path that starts with a slash."
          end

          # Get raw path by prepending output directory
          rep.raw_paths[snapshot] = @site.config[:output_dir] + basic_path

          # Get normal path by stripping index filename
          rep.paths[snapshot] = basic_path
          @site.config[:index_filenames].each do |index_filename|
            if rep.paths[snapshot][-index_filename.length..-1] == index_filename
              # Strip and stop
              rep.paths[snapshot] = rep.paths[snapshot][0..-index_filename.length-1]
              break
            end
          end
        end
      end
    end

    # @param [Nanoc::ItemRep] rep The item representation for which the
    #   assigns should be fetched
    #
    # @return [Hash] The assigns that should be used in the next filter/layout
    #   operation
    #
    # @api private
    def assigns_for(rep)
      if rep.binary?
        content_or_filename_assigns = { :filename => rep.temporary_filenames[:last] }
      else
        content_or_filename_assigns = { :content => rep.content[:last] }
      end

      content_or_filename_assigns.merge({
        :item       => rep.item,
        :item_rep   => rep,
        :items      => site.items,
        :layouts    => site.layouts,
        :config     => site.config,
        :site       => site
      })
    end

    # @return [Nanoc::OutdatednessChecker] The outdatedness checker
    def outdatedness_checker
      Nanoc::OutdatednessChecker.new(
        :site => @site,
        :checksum_store => checksum_store,
        :dependency_tracker => dependency_tracker)
    end
    memoize :outdatedness_checker

  private

    # @return [Array<Nanoc::Item>] The site’s items
    def items
      @site.items
    end
    memoize :items

    # @return [Array<Nanoc::ItemRep>] The site’s item representations
    def reps
      items.map { |i| i.reps }.flatten
    end
    memoize :reps

    # @return [Array<Nanoc::Layout>] The site’s layouts
    def layouts
      @site.layouts
    end
    memoize :layouts

    # Compiles the given representations.
    #
    # @param [Array] reps The item representations to compile.
    #
    # @return [void]
    def compile_reps(reps)
      content_dependency_graph = Nanoc::DirectedGraph.new(reps)

      # Listen to processing start/stop
      Nanoc::NotificationCenter.on(:processing_started, self) { |obj| @stack.push(obj) }
      Nanoc::NotificationCenter.on(:processing_ended,   self) { |obj| @stack.pop       }

      # Assign snapshots
      reps.each do |rep|
        rep.snapshots = rules_collection.snapshots_for(rep)
      end

      # Attempt to compile all active reps
      loop do
        # Find rep to compile
        break if content_dependency_graph.roots.empty?
        rep = content_dependency_graph.roots.each { |e| break e }
        @stack = []

        begin
          compile_rep(rep)
          content_dependency_graph.delete_vertex(rep)
        rescue Nanoc::Errors::UnmetDependency => e
          content_dependency_graph.add_edge(e.rep, rep)
          unless content_dependency_graph.vertices.include?(e.rep)
            content_dependency_graph.add_vertex(e.rep)
          end
        end
      end

      # Check whether everything was compiled
      if !content_dependency_graph.vertices.empty?
        raise Nanoc::Errors::RecursiveCompilation.new(content_dependency_graph.vertices)
      end
    ensure
      Nanoc::NotificationCenter.remove(:processing_started, self)
      Nanoc::NotificationCenter.remove(:processing_ended,   self)
    end

    # Compiles the given item representation.
    #
    # This method should not be called directly; please use
    # {Nanoc::Compiler#run} instead, and pass this item representation's item
    # as its first argument.
    #
    # @param [Nanoc::ItemRep] rep The rep that is to be compiled
    #
    # @return [void]
    def compile_rep(rep)
      Nanoc::NotificationCenter.post(:compilation_started, rep)
      Nanoc::NotificationCenter.post(:processing_started,  rep)
      Nanoc::NotificationCenter.post(:visit_started,       rep.item)

      # Calculate rule memory if we haven’t yet done do
      rules_collection.new_rule_memory_for_rep(rep)

      if !rep.item.forced_outdated? && !outdatedness_checker.outdated?(rep) && compiled_content_cache[rep]
        # Reuse content
        Nanoc::NotificationCenter.post(:cached_content_used, rep)
        rep.content = compiled_content_cache[rep]
      else
        # Recalculate content
        rep.snapshot(:raw)
        rep.snapshot(:pre, :final => false)
        rules_collection.compilation_rule_for(rep).apply_to(rep, :compiler => self)
        rep.snapshot(:post) if rep.has_snapshot?(:post)
        rep.snapshot(:last)
      end

      rep.compiled = true
      compiled_content_cache[rep] = rep.content

      Nanoc::NotificationCenter.post(:visit_ended,       rep.item)
      Nanoc::NotificationCenter.post(:processing_ended,  rep)
      Nanoc::NotificationCenter.post(:compilation_ended, rep)
    rescue => e
      rep.forget_progress
      Nanoc::NotificationCenter.post(:compilation_failed, rep, e)
      raise e
    end

    # Clears the list of dependencies for items that will be recompiled.
    #
    # @param [Array<Nanoc::Item>] items The list of items for which to forget
    #   the dependencies
    #
    # @return [void]
    def forget_dependencies_if_outdated(items)
      items.each do |i|
        if i.reps.any? { |r| outdatedness_checker.outdated?(r) }
          dependency_tracker.forget_dependencies_for(i)
        end
      end
    end

    # Returns a preprocessor context, creating one if none exists yet.
    def preprocessor_context
      Nanoc::Context.new({
        :site    => @site,
        :config  => @site.config,
        :items   => @site.items,
        :layouts => @site.layouts
      })
    end
    memoize :preprocessor_context

    # @return [CompiledContentCache] The compiled content cache
    def compiled_content_cache
      Nanoc::CompiledContentCache.new
    end
    memoize :compiled_content_cache

    # @return [ChecksumStore] The checksum store
    def checksum_store
      Nanoc::ChecksumStore.new(:site => @site)
    end
    memoize :checksum_store

    # @return [RuleMemoryStore] The rule memory store
    def rule_memory_store
      Nanoc::RuleMemoryStore.new(:site => @site)
    end
    memoize :rule_memory_store

    # @return [RuleMemoryCalculator] The rule memory calculator
    def rule_memory_calculator
      Nanoc::RuleMemoryCalculator.new(:rules_collection => rules_collection)
    end
    memoize :rule_memory_calculator

    # Returns all stores that can load/store data that can be used for
    # compilation.
    def stores
      [
        checksum_store,
        compiled_content_cache,
        dependency_tracker,
        rule_memory_store
      ]
    end

  end

end
