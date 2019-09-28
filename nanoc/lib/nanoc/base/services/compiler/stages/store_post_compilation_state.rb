# frozen_string_literal: true

module Nanoc
  module Base
    module CompilationStages
      class StorePostCompilationState < Nanoc::Core::CompilationStage
        include Nanoc::Core::ContractsSupport

        def initialize(dependency_store:)
          @dependency_store = dependency_store
        end

        contract C::None => C::Any
        def run
          @dependency_store.store
        end
      end
    end
  end
end
