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
      attr_reader :site
      attr_reader :compiled_content_cache
      attr_reader :snapshot_repo

      def initialize(action_provider:, reps:, site:, compiled_content_cache:, snapshot_repo:)
        @action_provider = action_provider
        @reps = reps
        @site = site
        @compiled_content_cache = compiled_content_cache
        @snapshot_repo = snapshot_repo
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
          snapshot_repo: @snapshot_repo,
        )
      end

      def assigns_for(rep, dependency_tracker)
        last_content = @snapshot_repo.get(rep, :last)
        content_or_filename_assigns =
          if last_content.binary?
            { filename: last_content.filename }
          else
            { content: last_content.string }
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

    # @api private
    attr_reader :snapshot_repo

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

      # TODO: inject
      @snapshot_repo = Nanoc::Int::SnapshotRepo.new
    end

    def run_all
      time_stage(:preprocess) { preprocess_stage.run }
      time_stage(:build_reps) { build_reps }
      time_stage(:prune) { prune_stage.run }
      time_stage(:load_stores) { load_stores }
      time_stage(:determine_outdatedness) { determine_outdatedness }
      time_stage(:forget_dependencies_if_needed) { forget_dependencies_if_needed }
      time_stage(:store) { store }
      time_stage(:compile_reps) { compile_reps_stage.run }
      time_stage(:store_output_state) { store_output_state }
      time_stage(:postprocess) { @action_provider.postprocess(@site, @reps) }
    ensure
      time_stage(:cleanup) { cleanup_stage.run }
    end

    def load_stores
      stores.each(&:load)
    end

    # TODO: rename to store_preprocessed_state
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
      checksum_store.store
      rule_memory_store.store
    end

    def store_output_state
      @dependency_store.store
    end

    def build_reps
      builder = Nanoc::Int::ItemRepBuilder.new(
        site, action_provider, @reps
      )
      @memories = builder.run
    end

    def compilation_context
      @_compilation_context ||= CompilationContext.new(
        action_provider: action_provider,
        reps: @reps,
        site: @site,
        compiled_content_cache: compiled_content_cache,
        snapshot_repo: snapshot_repo,
      )
    end

    private

    def time_stage(name)
      Nanoc::Int::NotificationCenter.post(:stage_started, name)
      yield
    ensure
      Nanoc::Int::NotificationCenter.post(:stage_ended, name)
    end

    def preprocess_stage
      @_preprocess_stage ||= Stages::Preprocess.new(
        action_provider: action_provider,
        site: site,
        dependency_store: dependency_store,
        checksum_store: checksum_store,
      )
    end

    def prune_stage
      @_prune_stage ||= Stages::Prune.new(
        config: site.config,
        reps: reps,
      )
    end

    def determine_outdatedness_stage
      @_determine_outdatedness_stage ||= Stages::DetermineOutdatedness.new(
        reps: reps,
        outdatedness_checker: outdatedness_checker,
        outdatedness_store: outdatedness_store,
      )
    end

    def compile_reps_stage
      @_compile_reps_stage ||= Stages::CompileReps.new(
        outdatedness_store: @outdatedness_store,
        dependency_store: @dependency_store,
        memories: @memories,
        compilation_context: compilation_context,
        compiled_content_cache: compiled_content_cache,
      )
    end

    def cleanup_stage
      @_cleanup_stage ||= Stages::Cleanup.new(site.config)
    end

    def determine_outdatedness
      determine_outdatedness_stage.run do |outdated_items|
        @outdated_items = outdated_items
      end
    end

    def forget_dependencies_if_needed
      @outdated_items.each { |i| @dependency_store.forget_dependencies_for(i) }
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
