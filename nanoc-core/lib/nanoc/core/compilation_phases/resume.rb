# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      # Provides functionality for suspending and resuming item rep compilation (using fibers).
      class Resume < Abstract
        include Nanoc::Core::ContractsSupport

        DONE = Object.new

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(rep, is_outdated:)
          fiber = fiber_for(rep, is_outdated: is_outdated) { yield }
          while fiber.alive?
            res = fiber.resume

            case res
            when Nanoc::Core::Errors::UnmetDependency
              Nanoc::Core::NotificationCenter.post(:compilation_suspended, rep, res.rep, res.snapshot_name)
              raise(res)
            when Proc
              fiber.resume(res.call)
            when DONE
              # ignore
            else
              raise Nanoc::Core::Errors::InternalInconsistency.new(
                "Fiber yielded object of unexpected type #{res.class}",
              )
            end
          end
        end

        private

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => Fiber
        def fiber_for(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          @fibers ||= {}

          @fibers[rep] ||=
            Fiber.new do
              yield
              @fibers.delete(rep)
              DONE
            end

          @fibers[rep]
        end
      end
    end
  end
end
