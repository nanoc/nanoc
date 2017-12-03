# frozen_string_literal: true

module Nanoc::Int::Compiler::Phases
  class Write < Abstract
    include Nanoc::Int::ContractsSupport

    def initialize(snapshot_repo:, wrapped:)
      super(wrapped: wrapped)

      @snapshot_repo = snapshot_repo
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
    def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
      yield

      Nanoc::Int::ItemRepWriter.new.write_all(rep, @snapshot_repo)
    end
  end
end
