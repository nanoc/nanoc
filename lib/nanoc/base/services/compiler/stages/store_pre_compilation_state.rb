module Nanoc::Int::Compiler::Stages
  class StorePreCompilationState
    include Nanoc::Int::ContractsSupport

    def initialize(reps:, layouts:, checksum_store:, action_sequence_store:, action_sequences:)
      @reps = reps
      @layouts = layouts
      @checksum_store = checksum_store
      @action_sequence_store = action_sequence_store
      @action_sequences = action_sequences
    end

    contract Nanoc::Int::ChecksumCollection => C::Any
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
