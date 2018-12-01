# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Stages
        class LoadStores < Nanoc::Int::Compiler::Stage
          include Nanoc::Core::ContractsSupport

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

          contract C::Or[Nanoc::Int::Store, Nanoc::Int::ThreadsafeCompiledContentCacheDecorator] => C::Any
          def load_store(store)
            Nanoc::Core::Instrumentor.call(:store_loaded, store.class) do
              store.load
            end
          end
        end
      end
    end
  end
end
