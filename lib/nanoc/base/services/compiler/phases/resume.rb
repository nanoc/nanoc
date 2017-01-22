module Nanoc::Int::Compiler::Phases
  # Provides functionality for suspending and resuming item rep compilation (using fibers).
  class Resume
    include Nanoc::Int::ContractsSupport

    def initialize(wrapped:)
      @wrapped = wrapped
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
    def run(rep, is_outdated:)
      fiber = fiber_for(rep, is_outdated: is_outdated)
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

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => Fiber
    def fiber_for(rep, is_outdated:)
      @fibers ||= {}

      @fibers[rep] ||=
        Fiber.new do
          @wrapped.run(rep, is_outdated: is_outdated)
          @fibers.delete(rep)
        end

      @fibers[rep]
    end
  end
end
