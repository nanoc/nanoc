# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Stages
        class CompileReps < Nanoc::Int::Compiler::Stage
          include Nanoc::Core::ContractsSupport
          include Nanoc::Assertions::Mixin

          def initialize(reps:, outdatedness_store:, dependency_store:, action_sequences:, compilation_context:, compiled_content_cache:)
            @reps = reps
            @outdatedness_store = outdatedness_store
            @dependency_store = dependency_store
            @action_sequences = action_sequences
            @compilation_context = compilation_context
            @compiled_content_cache = compiled_content_cache
          end

          def run
            outdated_reps = @reps.select { |r| @outdatedness_store.include?(r) }
            selector = Nanoc::Int::ItemRepSelector.new(outdated_reps)
            run_phase_stack do |phase_stack|
              selector.each do |rep|
                handle_errors_while(rep) do
                  compile_rep(rep, phase_stack: phase_stack, is_outdated: @outdatedness_store.include?(rep))
                end
              end
            end

            assert Nanoc::Assertions::AllItemRepsHaveCompiledContent.new(
              compiled_content_cache: @compiled_content_cache,
              item_reps: @reps,
            )
          ensure
            @outdatedness_store.store
            @compiled_content_cache.prune(items: @reps.map(&:item).uniq)
            @compiled_content_cache.store
          end

          private

          def handle_errors_while(item_rep)
            yield
          rescue Exception => e # rubocop:disable Lint/RescueException
            raise Nanoc::Int::Errors::CompilationError.new(e, item_rep)
          end

          def compile_rep(rep, phase_stack:, is_outdated:)
            phase_stack.call(rep, is_outdated: is_outdated)
          end

          def run_phase_stack
            yield(build_phase_stack)
          end

          def build_phase_stack
            recalculate_phase = Nanoc::Int::Compiler::Phases::Recalculate.new(
              action_sequences: @action_sequences,
              dependency_store: @dependency_store,
              compilation_context: @compilation_context,
            )

            cache_phase = Nanoc::Int::Compiler::Phases::Cache.new(
              compiled_content_cache: @compiled_content_cache,
              compiled_content_store: @compilation_context.compiled_content_store,
              wrapped: recalculate_phase,
            )

            resume_phase = Nanoc::Int::Compiler::Phases::Resume.new(
              wrapped: cache_phase,
            )

            write_phase = Nanoc::Int::Compiler::Phases::Write.new(
              compiled_content_store: @compilation_context.compiled_content_store,
              wrapped: resume_phase,
            )

            mark_done_phase = Nanoc::Int::Compiler::Phases::MarkDone.new(
              wrapped: write_phase,
              outdatedness_store: @outdatedness_store,
            )

            notify_phrase = Nanoc::Int::Compiler::Phases::Notify.new(
              wrapped: mark_done_phase,
            )

            notify_phrase
          end
        end
      end
    end
  end
end
