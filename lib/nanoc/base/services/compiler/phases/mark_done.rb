module Nanoc::Int::Compiler::Phases
  class MarkDone
    include Nanoc::Int::ContractsSupport

    def initialize(wrapped:, outdatedness_store:)
      @wrapped = wrapped
      @outdatedness_store = outdatedness_store
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
    def run(rep, is_outdated:)
      @wrapped.run(rep, is_outdated: is_outdated)
      @outdatedness_store.remove(rep)
    end
  end
end
