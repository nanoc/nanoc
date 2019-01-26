# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Phases
        class Write < Abstract
          include Nanoc::Core::ContractsSupport

          class Worker
            def initialize(queue:, compiled_content_store:)
              @queue = queue
              @compiled_content_store = compiled_content_store
            end

            def start
              @thread = Thread.new do
                Thread.current.abort_on_exception = true
                Thread.current.priority = -1 # schedule I/O work ASAP

                writer = Nanoc::Int::ItemRepWriter.new

                while rep = @queue.pop # rubocop:disable Lint/AssignmentInCondition
                  writer.write_all(rep, @compiled_content_store)
                end
              end
            end

            def join
              @thread.join
            end
          end

          class WorkerPool
            def initialize(queue:, size:, compiled_content_store:)
              @workers = Array.new(size) { Worker.new(queue: queue, compiled_content_store: compiled_content_store) }
            end

            def start
              @workers.each(&:start)
            end

            def join
              @workers.each(&:join)
            end
          end

          QUEUE_SIZE = 40
          WORKER_POOL_SIZE = 5

          def initialize(compiled_content_store:, wrapped:)
            super(wrapped: wrapped)

            @compiled_content_store = compiled_content_store

            @queue = SizedQueue.new(QUEUE_SIZE)
            @worker_pool = WorkerPool.new(queue: @queue, size: WORKER_POOL_SIZE, compiled_content_store: @compiled_content_store)
          end

          def start
            super
            @worker_pool.start
          end

          def stop
            super
            @queue.close
            @worker_pool.join
          end

          contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
          def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
            yield

            @queue << rep

            Nanoc::Core::NotificationCenter.post(:rep_write_enqueued, rep)
          end
        end
      end
    end
  end
end
