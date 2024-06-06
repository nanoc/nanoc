# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      class Write < Abstract
        include Nanoc::Core::ContractsSupport

        WORKER_POOL_SIZE = 5

        def initialize(compiled_content_store:, wrapped:)
          super(wrapped:)

          @compiled_content_store = compiled_content_store

          @pool = Concurrent::FixedThreadPool.new(WORKER_POOL_SIZE)

          @writer = Nanoc::Core::ItemRepWriter.new
        end

        def stop
          @pool.shutdown
          @pool.wait_for_termination

          super
        end

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          yield

          # Caution: Notification must be posted before enqueueing the rep,
          # or we risk a race condition where the :rep_write_ended
          # notification happens before the :rep_write_enqueued one.
          Nanoc::Core::NotificationCenter.post(:rep_write_enqueued, rep)

          @pool.post do
            @writer.write_all(rep, @compiled_content_store)
          end
        end
      end
    end
  end
end
