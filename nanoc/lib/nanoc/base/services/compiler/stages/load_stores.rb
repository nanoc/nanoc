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
      load_store(@checksum_store)
      load_store(@compiled_content_cache)
      load_store(@dependency_store)
      load_store(@action_sequence_store)
      load_store(@outdatedness_store)
    end

    contract Nanoc::Int::Store => C::Any
    def load_store(store)
      Nanoc::Int::Instrumentor.call(:store_loaded, store.class) do
        store.load
      end
    end
  end
end
