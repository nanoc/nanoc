module Nanoc::Int::Compiler::Stages
  class StorePreCompilationState
    include Nanoc::Int::ContractsSupport

    def initialize(reps:, layouts:, items:, code_snippets:, config:, checksum_store:, action_sequence_store:, action_sequences:)
      @reps = reps
      @layouts = layouts
      @items = items
      @code_snippets = code_snippets
      @config = config
      @checksum_store = checksum_store
      @action_sequence_store = action_sequence_store
      @action_sequences = action_sequences
    end

    contract C::None => C::Any
    def run
      # Calculate action sequence
      (@reps.to_a + @layouts.to_a).each do |obj|
        @action_sequence_store[obj] = @action_sequences[obj].serialize
      end

      # Calculate checksums
      objects_to_checksum =
        @items.to_a + @layouts.to_a + @code_snippets + [@config]
      objects_to_checksum.each { |obj| @checksum_store.add(obj) }

      # Store
      @checksum_store.store
      @action_sequence_store.store
    end
  end
end
