# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      class MarkDone < Abstract
        include Nanoc::Core::ContractsSupport

        def initialize(wrapped:, outdatedness_store:)
          super(wrapped:)

          @outdatedness_store = outdatedness_store
        end

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          yield
          @outdatedness_store.remove(rep)
        end
      end
    end
  end
end
