# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Stages
        class ForgetOutdatedDependencies < Nanoc::Core::CompilationStage
          include Nanoc::Core::ContractsSupport

          def initialize(dependency_store:)
            @dependency_store = dependency_store
          end

          contract C::IterOf[Nanoc::Core::Item] => C::Any
          def run(outdated_items)
            outdated_items.each { |i| @dependency_store.forget_dependencies_for(i) }
          end
        end
      end
    end
  end
end
