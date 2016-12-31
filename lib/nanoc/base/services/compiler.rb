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
  # @api private
  class Compiler
    # Provides common functionality for accesing “context” of an item that is being compiled.
    class CompilationContext
      def initialize(action_provider:, reps:, site:, compiled_content_cache:)
        @action_provider = action_provider
        @reps = reps
        @site = site
        @compiled_content_cache = compiled_content_cache
      end

      def filter_name_and_args_for_layout(layout)
        mem = @action_provider.memory_for(layout)
        if mem.nil? || mem.size != 1 || !mem[0].is_a?(Nanoc::Int::ProcessingActions::Filter)
          raise Nanoc::Int::Errors::UndefinedFilterForLayout.new(layout)
        end
        [mem[0].filter_name, mem[0].params]
      end

      def create_view_context(dependency_tracker)
        Nanoc::ViewContext.new(
          reps: @reps,
          items: @site.items,
          dependency_tracker: dependency_tracker,
          compilation_context: self,
        )
      end

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
          items: Nanoc::ItemCollectionWithRepsView.new(@site.items, view_context),
          layouts: Nanoc::LayoutCollectionView.new(@site.layouts, view_context),
          config: Nanoc::ConfigView.new(@site.config, view_context),
        )
      end

      def site
        @site
      end

      def compiled_content_cache
        @compiled_content_cache
      end
    end

    # All phases for the compilation of a single item rep. Phases will be repeated for every rep.
    module Phases
      # Provides functionality for (re)calculating the content of an item rep, without caching or
      # outdatedness checking.
      class Recalculate
        include Nanoc::Int::ContractsSupport

        def initialize(action_provider:, dependency_store:, compilation_context:)
          @action_provider = action_provider
          @dependency_store = dependency_store
          @compilation_context = compilation_context
        end

        contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
        def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          dependency_tracker = Nanoc::Int::DependencyTracker.new(@dependency_store)
          dependency_tracker.enter(rep.item)

          executor = Nanoc::Int::Executor.new(rep, @compilation_context, dependency_tracker)

          @action_provider.memory_for(rep).each do |action|
            case action
            when Nanoc::Int::ProcessingActions::Filter
              executor.filter(action.filter_name, action.params)
            when Nanoc::Int::ProcessingActions::Layout
              executor.layout(action.layout_identifier, action.params)
            when Nanoc::Int::ProcessingActions::Snapshot
              executor.snapshot(action.snapshot_name)
            else
              raise Nanoc::Int::Errors::InternalInconsistency, "unknown action #{action.inspect}"
            end
          end
        ensure
          dependency_tracker.exit
        end
      end

      # Provides functionality for (re)calculating the content of an item rep, with caching or
      # outdatedness checking. Delegates to s::Recalculate if outdated or no cache available.
      class Cache
        include Nanoc::Int::ContractsSupport

        def initialize(compiled_content_cache:, wrapped:)
          @compiled_content_cache = compiled_content_cache
          @wrapped = wrapped
        end

        contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
        def run(rep, is_outdated:)
          if can_reuse_content_for_rep?(rep, is_outdated: is_outdated)
            Nanoc::Int::NotificationCenter.post(:cached_content_used, rep)
            rep.snapshot_contents = @compiled_content_cache[rep]
          else
            @wrapped.run(rep, is_outdated: is_outdated)
          end

          rep.compiled = true
          @compiled_content_cache[rep] = rep.snapshot_contents
        end

        contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Bool
        def can_reuse_content_for_rep?(rep, is_outdated:)
          !is_outdated && !@compiled_content_cache[rep].nil?
        end
      end

      # Provides functionality for suspending and resuming item rep compilation (using fibers).
      class Resume
        include Nanoc::Int::ContractsSupport

        def initialize(wrapped:)
          @wrapped = wrapped
        end

        contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
        def run(rep, is_outdated:)
          fiber = fiber_for(rep, is_outdated: is_outdated)
          while fiber.alive?
            Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
            res = fiber.resume

            case res
            when Nanoc::Int::Errors::UnmetDependency
              Nanoc::Int::NotificationCenter.post(:compilation_suspended, rep, res)
              raise(res)
            when Proc
              fiber.resume(res.call)
            else
              # TODO: raise
            end
          end

          Nanoc::Int::NotificationCenter.post(:compilation_ended, rep)
        end

        private

        contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => Fiber
        def fiber_for(rep, is_outdated:)
          @fibers ||= {}

          @fibers[rep] ||=
            Fiber.new do
              @wrapped.run(rep, is_outdated: is_outdated)
              @fibers.delete(rep)
            end

          @fibers[rep]
        end
      end

      class Write
        include Nanoc::Int::ContractsSupport

        def initialize(wrapped:)
          @wrapped = wrapped
        end

        contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
        def run(rep, is_outdated:)
          @wrapped.run(rep, is_outdated: is_outdated)

          rep.snapshot_defs.each do |sdef|
            ItemRepWriter.new.write(rep, sdef.name)
          end
        end
      end

      class MarkDone
        include Nanoc::Int::ContractsSupport

        def initialize(wrapped:, outdatedness_store:)
          @wrapped = wrapped
          @outdatedness_store = outdatedness_store
        end

        contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
        def run(rep, is_outdated:)
          @wrapped.run(rep, is_outdated: is_outdated)
          @outdatedness_store.remove(rep)
        end
      end
    end

    module Stages
      class Preprocess
        def initialize(action_provider:, site:, dependency_store:, checksum_store:)
          @action_provider = action_provider
          @site = site
          @dependency_store = dependency_store
          @checksum_store = checksum_store
        end

        def run
          @action_provider.preprocess(@site)

          @dependency_store.objects = @site.items.to_a + @site.layouts.to_a
          @checksum_store.objects = @site.items.to_a + @site.layouts.to_a + @site.code_snippets + [@site.config]
        end
      end
    end

    include Nanoc::Int::ContractsSupport

    # @api private
    attr_reader :site

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

    # @api private
    attr_reader :outdatedness_store

    def initialize(site, compiled_content_cache:, checksum_store:, rule_memory_store:, action_provider:, dependency_store:, outdatedness_checker:, reps:, outdatedness_store:)
      @site = site

      @compiled_content_cache = compiled_content_cache
      @checksum_store         = checksum_store
      @rule_memory_store      = rule_memory_store
      @dependency_store       = dependency_store
      @outdatedness_checker   = outdatedness_checker
      @reps                   = reps
      @action_provider        = action_provider
      @outdatedness_store     = outdatedness_store
    end

    def run_all
      preprocess_stage.run
      build_reps
      prune
      run
      @action_provider.postprocess(@site, @reps)
    end

    def run
      load_stores
      @site.freeze
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
      objects_to_checksum.each { |obj| checksum_store.add(obj) }

      # Store
      stores.each(&:store)
    end

    def build_reps
      builder = Nanoc::Int::ItemRepBuilder.new(
        site, action_provider, @reps
      )
      builder.run
    end

    def compilation_context
      @_compilation_context ||= CompilationContext.new(
        action_provider: action_provider,
        reps: @reps,
        site: @site,
        compiled_content_cache: compiled_content_cache,
      )
    end

    private

    def preprocess_stage
      @_preprocess_stage ||= Stages::Preprocess.new(
        action_provider: action_provider,
        site: site,
        dependency_store: dependency_store,
        checksum_store: checksum_store,
      )
    end

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
      outdated_reps = @reps.select do |r|
        @outdatedness_store.include?(r) || outdatedness_checker.outdated?(r)
      end

      outdated_items = outdated_reps.map(&:item).uniq
      outdated_items.each { |i| @dependency_store.forget_dependencies_for(i) }

      reps_to_recompile = Set.new(outdated_items.flat_map { |i| @reps[i] })
      reps_to_recompile.each { |r| @outdatedness_store.add(r) }

      # FIXME: stores outdatedness twice
      store

      selector = Nanoc::Int::ItemRepSelector.new(reps_to_recompile)
      selector.each do |rep|
        handle_errors_while(rep) { compile_rep(rep, is_outdated: reps_to_recompile.include?(rep)) }
      end
    ensure
      @outdatedness_store.store
    end

    def handle_errors_while(item_rep)
      yield
    rescue => e
      raise Nanoc::Int::Errors::CompilationError.new(e, item_rep)
    end

    def compile_rep(rep, is_outdated:)
      item_rep_compiler.run(rep, is_outdated: is_outdated)
    end

    def item_rep_compiler
      @_item_rep_compiler ||= begin
        recalculate_phase = Phases::Recalculate.new(
          action_provider: action_provider,
          dependency_store: @dependency_store,
          compilation_context: compilation_context,
        )

        cache_phase = Phases::Cache.new(
          compiled_content_cache: compiled_content_cache,
          wrapped: recalculate_phase,
        )

        resume_phase = Phases::Resume.new(
          wrapped: cache_phase,
        )

        write_phase = Phases::Write.new(
          wrapped: resume_phase,
        )

        mark_done_phase = Phases::MarkDone.new(
          wrapped: write_phase,
          outdatedness_store: @outdatedness_store,
        )

        mark_done_phase
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
        @outdatedness_store,
      ]
    end
  end
end
