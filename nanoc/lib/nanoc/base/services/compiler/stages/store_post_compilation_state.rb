# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class StorePostCompilationState < Nanoc::Int::Compiler::Stage
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
