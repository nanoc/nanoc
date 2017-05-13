# frozen_string_literal: true

module Nanoc::Int::Compiler::Phases
  class MarkDone < Abstract
    include Nanoc::Int::ContractsSupport

    def initialize(wrapped:, outdatedness_store:)
      super(wrapped: wrapped)

      @outdatedness_store = outdatedness_store
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
    def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
      yield
      @outdatedness_store.remove(rep)
    end
  end
end
