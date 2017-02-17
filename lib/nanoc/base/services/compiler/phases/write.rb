module Nanoc::Int::Compiler::Phases
  class Write
    include Nanoc::Int::ContractsSupport

    def initialize(snapshot_repo:, wrapped:)
      @snapshot_repo = snapshot_repo
      @wrapped = wrapped
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
    def run(rep, is_outdated:)
      @wrapped.run(rep, is_outdated: is_outdated)

      Nanoc::Int::ItemRepWriter.new.write_all(rep, @snapshot_repo)
    end
  end
end
