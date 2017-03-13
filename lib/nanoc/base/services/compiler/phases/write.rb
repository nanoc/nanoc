module Nanoc::Int::Compiler::Phases
  class Write < Abstract
    include Nanoc::Int::ContractsSupport

    NAME = 'write'.freeze

    def initialize(snapshot_repo:, wrapped:)
      super(wrapped: wrapped, name: NAME)

      @snapshot_repo = snapshot_repo
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
    def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
      yield

      Nanoc::Int::ItemRepWriter.new.write_all(rep, @snapshot_repo)
    end
  end
end
