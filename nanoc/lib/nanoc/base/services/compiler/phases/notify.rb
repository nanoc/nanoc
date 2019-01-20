# frozen_string_literal: true

module Nanoc::Int::Compiler::Phases
  # Provides functionality for notifying start and end of compilation.
  class Notify < Abstract
    include Nanoc::Core::ContractsSupport

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
    def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
      Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
      yield
      Nanoc::Int::NotificationCenter.post(:compilation_ended, rep)
    end
  end
end
