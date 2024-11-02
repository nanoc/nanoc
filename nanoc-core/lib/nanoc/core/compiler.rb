# frozen_string_literal: true

module Nanoc
  module Core
    class Compiler
      include Nanoc::Core::ContractsSupport

      contract Nanoc::Core::Site => C::Any
      def self.compile(site, focus: nil)
        new_for(site, focus:).run_until_end
      end

      contract Nanoc::Core::Site => Nanoc::Core::Compiler
      def self.new_for(site, focus: nil)
        Nanoc::Core::CompilerLoader.new.load(site, focus:)
      end

      def initialize(site, compiled_content_cache:, checksum_store:, action_sequence_store:, action_provider:, dependency_store:, outdatedness_store:, focus:)
        @site = site

        # Needed because configuration is mutable :(
        @output_dirs = @site.config.output_dirs

        @compiled_content_cache = compiled_content_cache
        @checksum_store         = checksum_store
        @action_sequence_store  = action_sequence_store
        @dependency_store       = dependency_store
        @action_provider        = action_provider
        @outdatedness_store     = outdatedness_store
        @focus                  = focus

        @compiled_content_store = Nanoc::Core::CompiledContentStore.new
      end

      def run_until_preprocessed
        @_run_until_preprocessed ||= begin
          preprocess_stage.call
          {}
        end
      end

      def run_until_reps_built
        @_run_until_reps_built ||= begin
          prev = run_until_preprocessed

          res = build_reps_stage.call

          prev.merge(
            reps: res.fetch(:reps),
            action_sequences: res.fetch(:action_sequences),
          )
        end
      end

      def run_until_precompiled
        @_run_until_precompiled ||= begin
          prev = run_until_reps_built
          action_sequences = prev.fetch(:action_sequences)
          reps = prev.fetch(:reps)

          load_stores_stage.call
          checksums = calculate_checksums_stage.call
          outdatedness_checker = create_outdatedness_checker(
            checksums:,
            action_sequences:,
            reps:,
          )
          outdated_items = determine_outdatedness_stage(outdatedness_checker, reps).call

          prev.merge(
            checksums:,
            dependency_store: @dependency_store,
            outdatedness_checker:,
            outdated_items:,
          )
        end
      end

      def run_until_end
        res = run_until_precompiled
        action_sequences = res.fetch(:action_sequences)
        reps = res.fetch(:reps)
        checksums = res.fetch(:checksums)
        outdated_items = res.fetch(:outdated_items)

        forget_outdated_dependencies_stage.call(outdated_items)
        store_pre_compilation_state_stage(action_sequences, reps).call(checksums)
        prune_stage(reps).call
        compile_reps_stage(action_sequences, reps).call
        store_post_compilation_state_stage.call
        postprocess_stage.call(self)
      ensure
        cleanup_stage.call
      end

      def compilation_context(reps:)
        Nanoc::Core::CompilationContext.new(
          action_provider: @action_provider,
          reps:,
          site: @site,
          compiled_content_cache: @compiled_content_cache,
          compiled_content_store: @compiled_content_store,
        )
      end

      private

      def create_outdatedness_checker(checksums:, action_sequences:, reps:)
        Nanoc::Core::OutdatednessChecker.new(
          site: @site,
          checksum_store: @checksum_store,
          dependency_store: @dependency_store,
          action_sequence_store: @action_sequence_store,
          action_sequences:,
          checksums:,
          reps:,
        )
      end

      def preprocess_stage
        @_preprocess_stage ||= ::Nanoc::Core::CompilationStages::Preprocess.new(
          action_provider: @action_provider,
          site: @site,
          dependency_store: @dependency_store,
          checksum_store: @checksum_store,
        )
      end

      def build_reps_stage
        @_build_reps_stage ||= ::Nanoc::Core::CompilationStages::BuildReps.new(
          site: @site,
          action_provider: @action_provider,
        )
      end

      def prune_stage(reps)
        @_prune_stage ||= ::Nanoc::Core::CompilationStages::Prune.new(
          config: @site.config,
          reps:,
        )
      end

      def load_stores_stage
        @_load_stores_stage ||= ::Nanoc::Core::CompilationStages::LoadStores.new(
          checksum_store: @checksum_store,
          compiled_content_cache: @compiled_content_cache,
          dependency_store: @dependency_store,
          action_sequence_store: @action_sequence_store,
          outdatedness_store: @outdatedness_store,
        )
      end

      def calculate_checksums_stage
        @_calculate_checksums_stage ||= ::Nanoc::Core::CompilationStages::CalculateChecksums.new(
          items: @site.items,
          layouts: @site.layouts,
          code_snippets: @site.code_snippets,
          config: @site.config,
        )
      end

      def determine_outdatedness_stage(outdatedness_checker, reps)
        @_determine_outdatedness_stage ||= ::Nanoc::Core::CompilationStages::DetermineOutdatedness.new(
          reps:,
          outdatedness_checker:,
          outdatedness_store: @outdatedness_store,
        )
      end

      def store_pre_compilation_state_stage(action_sequences, reps)
        @_store_pre_compilation_state_stage ||= ::Nanoc::Core::CompilationStages::StorePreCompilationState.new(
          reps:,
          layouts: @site.layouts,
          checksum_store: @checksum_store,
          action_sequence_store: @action_sequence_store,
          action_sequences:,
        )
      end

      def compile_reps_stage(action_sequences, reps)
        @_compile_reps_stage ||= ::Nanoc::Core::CompilationStages::CompileReps.new(
          reps:,
          outdatedness_store: @outdatedness_store,
          dependency_store: @dependency_store,
          action_sequences:,
          compilation_context: compilation_context(reps:),
          compiled_content_cache: @compiled_content_cache,
          focus: @focus,
        )
      end

      def store_post_compilation_state_stage
        @_store_post_compilation_state_stage ||= ::Nanoc::Core::CompilationStages::StorePostCompilationState.new(
          dependency_store: @dependency_store,
        )
      end

      def postprocess_stage
        @_postprocess_stage ||= ::Nanoc::Core::CompilationStages::Postprocess.new(
          action_provider: @action_provider,
          site: @site,
        )
      end

      def cleanup_stage
        @_cleanup_stage ||= ::Nanoc::Core::CompilationStages::Cleanup.new(@output_dirs)
      end

      def forget_outdated_dependencies_stage
        @_forget_outdated_dependencies_stage ||= ::Nanoc::Core::CompilationStages::ForgetOutdatedDependencies.new(
          dependency_store: @dependency_store,
        )
      end
    end
  end
end
