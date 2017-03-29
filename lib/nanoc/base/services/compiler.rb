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
        mem = @action_provider.action_sequence_for(layout)
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
    attr_reader :action_sequence_store

    # @api private
    attr_reader :action_provider

    # @api private
    attr_reader :dependency_store

    # @api private
    attr_reader :reps

    # @api private
    attr_reader :outdatedness_store

    # @api private
    attr_reader :snapshot_repo

    def initialize(site, compiled_content_cache:, checksum_store:, action_sequence_store:, action_provider:, dependency_store:, reps:, outdatedness_store:)
      @site = site

      @compiled_content_cache = compiled_content_cache
      @checksum_store         = checksum_store
      @action_sequence_store  = action_sequence_store
      @dependency_store       = dependency_store
      @reps                   = reps
      @action_provider        = action_provider
      @outdatedness_store     = outdatedness_store

      # TODO: inject
      @snapshot_repo = Nanoc::Int::SnapshotRepo.new
    end

    def create_outdatedness_checker
      Nanoc::Int::OutdatednessChecker.new(
        site: @site,
        checksum_store: @checksum_store,
        dependency_store: @dependency_store,
        action_sequence_store: @action_sequence_store,
        action_sequences: @action_sequences,
        reps: reps,
      )
    end

    def run_all
      time_stage(:preprocess) { preprocess_stage.run }
      time_stage(:build_reps) { build_reps }
      time_stage(:prune) { prune_stage.run }
      time_stage(:load_stores) { load_stores_stage.run }
      @outdated_items = time_stage(:determine_outdatedness) { determine_outdatedness_stage.run }
      time_stage(:forget_outdated_dependencies) { forget_outdated_dependencies_stage.run }
      time_stage(:store_pre_compilation_state) { store_pre_compilation_state_stage.run }
      time_stage(:compile_reps) { compile_reps_stage.run }
      time_stage(:store_post_compilation_state) { store_post_compilation_state_stage.run }
      time_stage(:postprocess) { postprocess_stage.run }
    ensure
      time_stage(:cleanup) { cleanup_stage.run }
    end

    def build_reps
      # FIXME: This also, as a side effect, generates the action sequences. :(
      # Better: let this stage return a mapping of reps onto (raw) paths *and* a mapping of objects
      # onto action sequences.

      builder = Nanoc::Int::ItemRepBuilder.new(
        site, action_provider, @reps
      )

      @action_sequences = builder.run

      @site.layouts.each do |layout|
        @action_sequences[layout] = action_provider.action_sequence_for(layout)
      end
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

    # TODO: remove
    def load_stores
      load_stores_stage.run
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

    def load_stores_stage
      @_load_stores_stage ||= Stages::LoadStores.new(
        checksum_store: checksum_store,
        compiled_content_cache: compiled_content_cache,
        dependency_store: @dependency_store,
        action_sequence_store: action_sequence_store,
        outdatedness_store: @outdatedness_store,
      )
    end

    def determine_outdatedness_stage
      @_determine_outdatedness_stage ||= Stages::DetermineOutdatedness.new(
        reps: reps,
        outdatedness_checker: create_outdatedness_checker,
        outdatedness_store: outdatedness_store,
      )
    end

    def store_pre_compilation_state_stage
      @_store_pre_compilation_state_stage ||= Stages::StorePreCompilationState.new(
        reps: @reps,
        layouts: site.layouts,
        items: site.items,
        code_snippets: site.code_snippets,
        config: site.config,
        checksum_store: checksum_store,
        action_sequence_store: action_sequence_store,
        action_sequences: @action_sequences,
      )
    end

    def compile_reps_stage
      @_compile_reps_stage ||= Stages::CompileReps.new(
        outdatedness_store: @outdatedness_store,
        dependency_store: @dependency_store,
        action_sequences: @action_sequences,
        compilation_context: compilation_context,
        compiled_content_cache: compiled_content_cache,
      )
    end

    def store_post_compilation_state_stage
      @_store_post_compilation_state_stage ||= Stages::StorePostCompilationState.new(
        dependency_store: dependency_store,
      )
    end

    def postprocess_stage
      @_postprocess_stage ||= Stages::Postprocess.new(
        action_provider: @action_provider,
        site: @site,
        reps: @reps,
      )
    end

    def cleanup_stage
      @_cleanup_stage ||= Stages::Cleanup.new(site.config)
    end

    def forget_outdated_dependencies_stage
      @_forget_outdated_dependencies_stage ||= Stages::ForgetOutdatedDependencies.new(
        outdated_items: @outdated_items,
        dependency_store: @dependency_store,
      )
    end
  end
end
