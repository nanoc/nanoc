# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      class Abstract
        include Nanoc::Core::ContractsSupport

        def initialize(wrapped:)
          @wrapped = wrapped
        end

        def start
          @wrapped&.start
        end

        def stop
          @wrapped&.stop
        end

        def call(rep, is_outdated:)
          notify(:phase_started, rep)
          run(rep, is_outdated:) do
            notify(:phase_yielded, rep)
            @wrapped.call(rep, is_outdated:)
            notify(:phase_resumed, rep)
          end
          notify(:phase_ended, rep)
        rescue
          notify(:phase_aborted, rep)
          raise
        end

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(_rep, is_outdated:)
          raise NotImplementedError
        end

        private

        def notify(sym, rep)
          name = self.class.to_s.sub(/^.*::/, '')
          Nanoc::Core::NotificationCenter.post(sym, name, rep)
        end
      end
    end
  end
end
