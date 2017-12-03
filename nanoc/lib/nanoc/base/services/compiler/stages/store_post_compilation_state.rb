# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class StorePostCompilationState
    include Nanoc::Int::ContractsSupport

    def initialize(dependency_store:)
      @dependency_store = dependency_store
    end

    contract C::None => C::Any
    def run
      @dependency_store.store
    end
  end
end
