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

      rep.snapshot_defs.each do |sdef|
        Nanoc::Int::ItemRepWriter.new.write(rep, @snapshot_repo, sdef.name)
      end
    end
  end
end
