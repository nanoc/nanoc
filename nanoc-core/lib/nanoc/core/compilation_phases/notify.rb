# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      # Provides functionality for notifying start and end of compilation.
      class Notify < Abstract
        include Nanoc::Core::ContractsSupport

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
          yield
          Nanoc::Core::NotificationCenter.post(:compilation_ended, rep)
        end
      end
    end
  end
end
