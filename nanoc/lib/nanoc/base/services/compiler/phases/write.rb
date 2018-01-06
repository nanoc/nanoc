# frozen_string_literal: true

module Nanoc::Int::Compiler::Phases
  class Write < Abstract
    include Nanoc::Int::ContractsSupport

    def initialize(snapshot_repo:, wrapped:)
      super(wrapped: wrapped)

      @snapshot_repo = snapshot_repo

      @queue_to_write = SizedQueue.new(1000)
    end

    def start
      super

      @thread = Thread.new do
        Thread.current.abort_on_exception = true
        Thread.current.priority = -1 # schedule I/O work ASAP

        writer = Nanoc::Int::ItemRepWriter.new

        while rep = @queue_to_write.pop # rubocop:disable Lint/AssignmentInCondition
          writer.write_all(rep, @snapshot_repo)
        end
      end
    end

    def stop
      super

      @queue_to_write.close
      @thread.join
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
    def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
      yield

      @queue_to_write << rep

      Nanoc::Int::NotificationCenter.post(:rep_write_enqueued, rep)
    end
  end
end
