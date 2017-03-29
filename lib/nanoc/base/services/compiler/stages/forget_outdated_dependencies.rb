module Nanoc::Int::Compiler::Stages
  class ForgetOutdatedDependencies
    include Nanoc::Int::ContractsSupport

    def initialize(outdated_items:, dependency_store:)
      @outdated_items = outdated_items
      @dependency_store = dependency_store
    end

    contract C::None => C::Any
    def run
      @outdated_items.each { |i| @dependency_store.forget_dependencies_for(i) }
    end
  end
end
