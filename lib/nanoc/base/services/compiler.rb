# frozen_string_literal: true

module Nanoc::Int
  class Compiler
    include Nanoc::Int::ContractsSupport

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

    def run_until_preprocessed
      @_res_preprocessed ||= begin
        run_stage(preprocess_stage)
        {}
      end
    end

    def run_until_reps_built
      @_res_reps_built ||= begin
        run_until_preprocessed

        # NOTE: build_reps_stage mutates @reps
        action_sequences = run_stage(build_reps_stage)

        {
          reps: @reps,
          action_sequences: action_sequences,
        }
      end
    end

    def run_until_precompiled
      @_res_precompiled ||= begin
        res = run_until_reps_built
        action_sequences = res.fetch(:action_sequences)

        run_stage(load_stores_stage)
        checksums = run_stage(calculate_checksums_stage)
        outdatedness_checker = create_outdatedness_checker(
          checksums: checksums,
          action_sequences: action_sequences,
        )
        outdated_items = run_stage(determine_outdatedness_stage(outdatedness_checker))

        res.merge(
          checksums: checksums,
          dependency_store: @dependency_store,
          outdatedness_checker: outdatedness_checker,
          outdated_items: outdated_items,
        )
      end
    end

    def run_all
      res = run_until_precompiled
      action_sequences = res.fetch(:action_sequences)
      checksums = res.fetch(:checksums)
      outdated_items = res.fetch(:outdated_items)

      run_stage(forget_outdated_dependencies_stage, outdated_items)
      run_stage(store_pre_compilation_state_stage(action_sequences), checksums)
      run_stage(prune_stage)
      run_stage(compile_reps_stage(action_sequences))
      run_stage(store_post_compilation_state_stage)
      run_stage(postprocess_stage)
    ensure
      run_stage(cleanup_stage)
    end

    def compilation_context
      @_compilation_context ||= Nanoc::Int::CompilationContext.new(
        action_provider: @action_provider,
        reps: @reps,
        site: @site,
        compiled_content_cache: @compiled_content_cache,
        snapshot_repo: @snapshot_repo,
      )
    end

    private

    def run_stage(stage, *args)
      Nanoc::Int::NotificationCenter.post(:stage_started, stage.class)
      stage.run(*args)
    ensure
      Nanoc::Int::NotificationCenter.post(:stage_ended, stage.class)
    end

    def create_outdatedness_checker(checksums:, action_sequences:)
      Nanoc::Int::OutdatednessChecker.new(
        site: @site,
        checksum_store: @checksum_store,
        dependency_store: @dependency_store,
        action_sequence_store: @action_sequence_store,
        action_sequences: action_sequences,
        checksums: checksums,
        reps: @reps,
      )
    end

    def preprocess_stage
      @_preprocess_stage ||= Stages::Preprocess.new(
        action_provider: @action_provider,
        site: @site,
        dependency_store: @dependency_store,
        checksum_store: @checksum_store,
      )
    end

    def build_reps_stage
      @_build_reps_stage ||= Stages::BuildReps.new(
        site: @site,
        action_provider: @action_provider,
        reps: @reps,
      )
    end

    def prune_stage
      @_prune_stage ||= Stages::Prune.new(
        config: @site.config,
        reps: @reps,
      )
    end

    def load_stores_stage
      @_load_stores_stage ||= Stages::LoadStores.new(
        checksum_store: @checksum_store,
        compiled_content_cache: @compiled_content_cache,
        dependency_store: @dependency_store,
        action_sequence_store: @action_sequence_store,
        outdatedness_store: @outdatedness_store,
      )
    end

    def calculate_checksums_stage
      @_calculate_checksums_stage ||= Stages::CalculateChecksums.new(
        items: @site.items,
        layouts: @site.layouts,
        code_snippets: @site.code_snippets,
        config: @site.config,
      )
    end

    def determine_outdatedness_stage(outdatedness_checker)
      @_determine_outdatedness_stage ||= Stages::DetermineOutdatedness.new(
        reps: @reps,
        outdatedness_checker: outdatedness_checker,
        outdatedness_store: @outdatedness_store,
      )
    end

    def store_pre_compilation_state_stage(action_sequences)
      @_store_pre_compilation_state_stage ||= Stages::StorePreCompilationState.new(
        reps: @reps,
        layouts: @site.layouts,
        checksum_store: @checksum_store,
        action_sequence_store: @action_sequence_store,
        action_sequences: action_sequences,
      )
    end

    def compile_reps_stage(action_sequences)
      @_compile_reps_stage ||= Stages::CompileReps.new(
        outdatedness_store: @outdatedness_store,
        dependency_store: @dependency_store,
        action_sequences: action_sequences,
        compilation_context: compilation_context,
        compiled_content_cache: @compiled_content_cache,
      )
    end

    def store_post_compilation_state_stage
      @_store_post_compilation_state_stage ||= Stages::StorePostCompilationState.new(
        dependency_store: @dependency_store,
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
      @_cleanup_stage ||= Stages::Cleanup.new(@site.config)
    end

    def forget_outdated_dependencies_stage
      @_forget_outdated_dependencies_stage ||= Stages::ForgetOutdatedDependencies.new(
        dependency_store: @dependency_store,
      )
    end
  end
end
