# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class CompileReps
    def initialize(outdatedness_store:, dependency_store:, action_sequences:, compilation_context:, compiled_content_cache:)
      @outdatedness_store = outdatedness_store
      @dependency_store = dependency_store
      @action_sequences = action_sequences
      @compilation_context = compilation_context
      @compiled_content_cache = compiled_content_cache
    end

    def run
      selector = Nanoc::Int::ItemRepSelector.new(@outdatedness_store.to_a)
      selector.each do |rep|
        handle_errors_while(rep) { compile_rep(rep, is_outdated: @outdatedness_store.include?(rep)) }
      end
    ensure
      @outdatedness_store.store
      @compiled_content_cache.store
    end

    private

    def handle_errors_while(item_rep)
      yield
    rescue => e
      raise Nanoc::Int::Errors::CompilationError.new(e, item_rep)
    end

    def compile_rep(rep, is_outdated:)
      item_rep_compiler.call(rep, is_outdated: is_outdated)
    end

    def item_rep_compiler
      @_item_rep_compiler ||= begin
        recalculate_phase = Nanoc::Int::Compiler::Phases::Recalculate.new(
          action_sequences: @action_sequences,
          dependency_store: @dependency_store,
          compilation_context: @compilation_context,
        )

        cache_phase = Nanoc::Int::Compiler::Phases::Cache.new(
          compiled_content_cache: @compiled_content_cache,
          snapshot_repo: @compilation_context.snapshot_repo,
          wrapped: recalculate_phase,
        )

        resume_phase = Nanoc::Int::Compiler::Phases::Resume.new(
          wrapped: cache_phase,
        )

        write_phase = Nanoc::Int::Compiler::Phases::Write.new(
          snapshot_repo: @compilation_context.snapshot_repo,
          wrapped: resume_phase,
        )

        mark_done_phase = Nanoc::Int::Compiler::Phases::MarkDone.new(
          wrapped: write_phase,
          outdatedness_store: @outdatedness_store,
        )

        mark_done_phase
      end
    end
  end
end
