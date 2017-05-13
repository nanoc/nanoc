# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class ForgetOutdatedDependencies
    include Nanoc::Int::ContractsSupport

    def initialize(dependency_store:)
      @dependency_store = dependency_store
    end

    contract C::IterOf[Nanoc::Int::Item] => C::Any
    def run(outdated_items)
      outdated_items.each { |i| @dependency_store.forget_dependencies_for(i) }
    end
  end
end
