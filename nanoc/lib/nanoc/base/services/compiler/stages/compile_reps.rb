# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Stages
        class CompileReps < Nanoc::Int::Compiler::Stage
          include Nanoc::Core::ContractsSupport
          include Nanoc::Assertions::Mixin

          class State
            # Reps that have not yet been compiled
            attr_reader :pending_reps

            # Reps that are currently being compiled
            attr_reader :live_reps

            # Reps that have been compiled
            attr_reader :completed_reps

            def initialize(outdated_reps)
              @pending_reps = Set.new(outdated_reps)
              @live_reps = Set.new
              @completed_reps = Set.new
            end

            # Returns any pending rep, or nil if none exist. Does not modify state.
            def take
              if @pending_reps.empty?
                nil
              else
                @pending_reps.each { |e| break e }
              end
            end

            # Marks the given rep as live, i.e. currently being compiled.
            #
            # Should not be called on a rep that is already being compiled, or already
            # finished compiling.
            def mark_as_live(rep)
              @pending_reps.delete(rep)
              @live_reps << rep
            end

            # Marks the given rep as completed, i.e. finished compiling.
            #
            # Should not be called on a rep that is pending, or already finished
            # compiling.
            def mark_as_completed(rep)
              @live_reps.delete(rep)
              @completed_reps << rep
            end

            # Whether or not this rep is outdated, i.e. pending.
            def outdated?(rep)
              @pending_reps.include?(rep)
            end

            # Whether or not there are no reps left that are either pending (i.e.
            # not yet compiled) or live (i.e. being compile).
            def done?
              @pending_reps.empty? && @live_reps.empty?
            end

            # Whether or not the rep is being compiled or finished compiling.
            def in_progress_or_done?(rep)
              @live_reps.include?(rep) || @completed_reps.include?(rep)
            end
          end

          # A wrapper for a thread pool that keeps track of the number of in-progress
          # tasks.
          class CountingThreadPool
            extend Forwardable

            def_delegators :@wrapped, :shutdown, :kill, :wait_for_termination

            def initialize(wrapped)
              @wrapped = wrapped

              @count = Concurrent::AtomicFixnum.new(0)
            end

            def count
              @count.value
            end

            def post
              @count.increment

              @wrapped.post do
                begin
                  yield
                ensure
                  @count.decrement
                end
              end
            end
          end

          class ThreadPool
            def initialize(queue:, state:, phase_stack:, parallelism:)
              @queue = queue
              @state = state
              @phase_stack = phase_stack
              @parallelism = parallelism

              # Thread pool for all outdated reps.
              # Bounded, to limit parallelism to some degree.
              @main_thread_pool =
                CountingThreadPool.new(
                  Concurrent::FixedThreadPool.new(parallelism, max_queue: 1),
                )

              # Thread pool for dependencies of outdated reps.
              # Unbounded to prevent deadlocks, but will likely remain small.
              @extra_thread_pool = Concurrent::CachedThreadPool.new
            end

            def schedule_main(rep)
              schedule(rep, pool: @main_thread_pool, is_outdated: true)
            end

            def schedule_extra(rep, is_outdated:)
              schedule(rep, pool: @extra_thread_pool, is_outdated: is_outdated)
            end

            def main_free?
              @main_thread_pool.count < @parallelism
            end

            def shutdown
              @main_thread_pool.shutdown
              @extra_thread_pool.shutdown
            end

            def kill
              @main_thread_pool.kill
              @extra_thread_pool.kill
            end

            def wait_for_termination
              @main_thread_pool.wait_for_termination
              @extra_thread_pool.wait_for_termination
            end

            private

            def schedule(rep, pool:, is_outdated:)
              @state.mark_as_live(rep)

              pool.post do
                begin
                  @phase_stack.call(rep, is_outdated: is_outdated)
                rescue Exception => e # rubocop:disable Lint/RescueException
                  # NOTE: We rescue Exception instead of StandardError, because this
                  # exception will be re-raised by the main thread later anyway.
                  @queue << [:error, rep, e]
                end
                @queue << [:done, rep]
              end
            end
          end

          class DeadlockDetector
            def initialize
              # FIXME: this will not work properly -- need (rep, snapshot_name) -> (rep, snapshot_name) dependencies, rather than rep -> rep

              @graph = Nanoc::Core::DirectedGraph.new([])
            end

            def hard_dependency_detected(source_rep, target_rep, _target_snapshot_name)
              @graph.add_edge(source_rep, target_rep)

              # TODO: detect deadlocks
              # We know the snapshots for each rep, and we can track all the hard
              # dependencies. Therefore, we can also detect loops that will cause
              # deadlocks.

              predecessors = @graph.predecessors_of(source_rep)
              if predecessors.include?(source_rep)
                raise Nanoc::Int::Errors::DependencyCycle, predecessors.to_a
              else
              end
            end
          end

          class ParallelismCoordinator
            PARALLELISM = Concurrent.processor_count

            def initialize(outdated_reps:, phase_stack:)
              @phase_stack = phase_stack
              @state = State.new(outdated_reps)
              @queue = SizedQueue.new(PARALLELISM * 2)
              @thread_pool = ThreadPool.new(queue: @queue, state: @state, phase_stack: @phase_stack, parallelism: PARALLELISM)
            end

            def run
              setup_notifications
              schedule_initial

              deadlock_detector = DeadlockDetector.new

              loop do
                break if @state.done?

                handle_next(deadlock_detector)
              end

              # Shut down and wait (safe)
              @thread_pool.shutdown
              @thread_pool.wait_for_termination
            rescue => e
              # Shut down and don’t wait
              @thread_pool.kill
              raise e
            ensure
              shutdown_notifications
            end

            private

            def handle_next(deadlock_detector)
              event = @queue.pop
              name = event[0]
              rep = event[1]

              case name
              when :compilation_interrupted
                target_rep = event[2]
                target_snapshot_name = event[3]

                deadlock_detector.hard_dependency_detected(rep, target_rep, target_snapshot_name)

                unless @state.in_progress_or_done?(target_rep)
                  @thread_pool.schedule_extra(target_rep, is_outdated: @state.outdated?(target_rep))
                end

              when :error
                error = event[2]
                raise Nanoc::Int::Errors::CompilationError.new(error, rep)

              when :done
                @state.mark_as_completed(rep)

                # Schedule next item rep for compilation
                if @thread_pool.main_free?
                  if (new_rep = @state.take)
                    @thread_pool.schedule_main(new_rep)
                  end
                end

              else
                raise Nanoc::Int::Errors::InternalInconsistency, 'Unhandled event type'
              end
            end

            def setup_notifications
              # FIXME: using notifications for this is not great.

              Nanoc::Core::NotificationCenter.on(:compilation_interrupted, self) do |rep, target_rep, target_snapshot_name|
                @queue << [:compilation_interrupted, rep, target_rep, target_snapshot_name]
              end
            end

            def shutdown_notifications
              Nanoc::Core::NotificationCenter.remove(:compilation_interrupted, self)
            end

            def schedule_initial
              PARALLELISM.times do
                # Find a pending rep
                rep = @state.take
                break unless rep

                # Schedule it
                @thread_pool.schedule_main(rep)
              end
            end
          end

          def initialize(reps:, outdatedness_store:, dependency_store:, action_sequences:, compilation_context:, compiled_content_cache:)
            @reps = reps
            @outdatedness_store = outdatedness_store
            @dependency_store = dependency_store
            @action_sequences = action_sequences
            @compilation_context = compilation_context
            @compiled_content_cache = compiled_content_cache
          end

          def run
            phase_stack = build_phase_stack

            ParallelismCoordinator.new(
              phase_stack: phase_stack,
              outdated_reps: @reps.select { |r| @outdatedness_store.include?(r) },
            ).run

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
