# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class LoadStores
    include Nanoc::Int::ContractsSupport

    def initialize(checksum_store:, compiled_content_cache:, dependency_store:, action_sequence_store:, outdatedness_store:)
      @checksum_store = checksum_store
      @compiled_content_cache = compiled_content_cache
      @dependency_store = dependency_store
      @action_sequence_store = action_sequence_store
      @outdatedness_store = outdatedness_store
    end

    contract C::None => C::Any
    def run
      @checksum_store.load
      @compiled_content_cache.load
      @dependency_store.load
      @action_sequence_store.load
      @outdatedness_store.load
    end
  end
end
