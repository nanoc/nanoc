# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Stages
        class StorePreCompilationState < Nanoc::Core::CompilationStage
          include Nanoc::Core::ContractsSupport

          def initialize(reps:, layouts:, checksum_store:, action_sequence_store:, action_sequences:)
            @reps = reps
            @layouts = layouts
            @checksum_store = checksum_store
            @action_sequence_store = action_sequence_store
            @action_sequences = action_sequences
          end

          contract Nanoc::Core::ChecksumCollection => C::Any
          def run(checksums)
            # Calculate action sequence
            (@reps.to_a + @layouts.to_a).each do |obj|
              @action_sequence_store[obj] = @action_sequences[obj].serialize
            end
            @action_sequence_store.store

            # Set checksums
            @checksum_store.checksums = checksums.to_h
            @checksum_store.store
          end
        end
      end
    end
  end
end
