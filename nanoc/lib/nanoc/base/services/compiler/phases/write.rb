# frozen_string_literal: true

module Nanoc::Int::Compiler::Phases
  class Write < Abstract
    include Nanoc::Int::ContractsSupport

    class Worker
      def initialize(queue:, snapshot_repo:)
        @queue = queue
        @snapshot_repo = snapshot_repo
      end

      def start
        @thread = Thread.new do
          Thread.current.abort_on_exception = true
          Thread.current.priority = -1 # schedule I/O work ASAP

          writer = Nanoc::Int::ItemRepWriter.new

          while rep = @queue.pop # rubocop:disable Lint/AssignmentInCondition
            writer.write_all(rep, @snapshot_repo)
          end
        end
      end

      def join
        @thread.join
      end
    end

    class WorkerPool
      def initialize(queue:, size:, snapshot_repo:)
        @workers = Array.new(size) { Worker.new(queue: queue, snapshot_repo: snapshot_repo) }
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

    def initialize(snapshot_repo:, wrapped:)
      super(wrapped: wrapped)

      @snapshot_repo = snapshot_repo

      @queue = SizedQueue.new(QUEUE_SIZE)
      @worker_pool = WorkerPool.new(queue: @queue, size: WORKER_POOL_SIZE, snapshot_repo: @snapshot_repo)
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

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
    def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
      yield

      @queue << rep

      Nanoc::Int::NotificationCenter.post(:rep_write_enqueued, rep)
    end
  end
end
