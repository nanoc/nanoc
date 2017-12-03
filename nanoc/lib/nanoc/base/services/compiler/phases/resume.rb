# frozen_string_literal: true

module Nanoc::Int::Compiler::Phases
  # Provides functionality for suspending and resuming item rep compilation (using fibers).
  class Resume < Abstract
    include Nanoc::Int::ContractsSupport

    def initialize(wrapped:)
      super(wrapped: wrapped)
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
    def run(rep, is_outdated:)
      fiber = fiber_for(rep, is_outdated: is_outdated) { yield }
      while fiber.alive?
        Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
        res = fiber.resume

        case res
        when Nanoc::Int::Errors::UnmetDependency
          Nanoc::Int::NotificationCenter.post(:compilation_suspended, rep, res)
          raise(res)
        when Proc
          fiber.resume(res.call)
        else
          # TODO: raise
        end
      end

      Nanoc::Int::NotificationCenter.post(:compilation_ended, rep)
    end

    private

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => Fiber
    def fiber_for(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
      @fibers ||= {}

      @fibers[rep] ||=
        Fiber.new do
          yield
          @fibers.delete(rep)
        end

      @fibers[rep]
    end
  end
end
