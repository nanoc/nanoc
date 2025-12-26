# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      class Write < Abstract
        include Nanoc::Core::ContractsSupport

        def initialize(compiled_content_repo:, wrapped:)
          super(wrapped:)

          @compiled_content_repo = compiled_content_repo

          @writer = Nanoc::Core::ItemRepWriter.new
        end

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          yield

          # Caution: Notification must be posted before enqueueing the rep,
          # or we risk a race condition where the :rep_write_ended
          # notification happens before the :rep_write_enqueued one.
          Nanoc::Core::NotificationCenter.post(:rep_write_enqueued, rep)

          @writer.write_all(rep, @compiled_content_repo)
        end
      end
    end
  end
end
